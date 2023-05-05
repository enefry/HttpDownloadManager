//
//  File.swift
//
//
//  Created by 陈任伟 on 2022/12/19.
//

import Combine
import Foundation
import LoggerProxy
import Tiercel
import UIKit

class HttpDownloadManagerImpl: DownloadManagerApi {
    func getWorkingPath() -> String {
        session.cache.downloadPath
    }

    func getDownloadedPath() -> String {
        session.cache.downloadFilePath
    }

    func getCachePath() -> String {
        session.cache.downloadTmpPath
    }

    var configure: Configuration

    func getConfigure() -> Configuration {
        return configure
    }

    public static var defaultWorkingPath: (String?,String?,String?)? = nil
    public static let defaultManager = {
        HttpDownloadManagerImpl(identifier: "HttpDownloadManager.default", cachePath: defaultWorkingPath)
    }()

    var eventPublisher = PassthroughSubject<Event, Never>()
    var events: [AnyCancellable] = []
    public init(identifier: String, cachePath: (String?,String?,String?)? = nil) {
        let logger = Logger(identifier: identifier)
        self.logger = logger

        let configure = Configuration(identifier: identifier)
        configure.load()
        self.configure = configure
        let cache = Tiercel.Cache(identifier, downloadPath: cachePath?.0,downloadTmpPath: cachePath?.1,downloadFilePath: cachePath?.2)
        let session = SessionManager(identifier, configuration: configure.toSessionConfigure(), logger: logger, cache: cache)
        self.session = session
        // 变换设置
        configure.$timeoutIntervalForRequest.debounce(for: 0.1, scheduler: RunLoop.main).removeDuplicates().sink { [session, weak configure] value in
            session.configuration.timeoutIntervalForRequest = value
            configure?.timeoutIntervalForRequest = session.configuration.timeoutIntervalForRequest
            configure?.save()
        }.store(in: &events)

        configure.$maxConcurrentTasksLimit.debounce(for: 0.1, scheduler: RunLoop.main).removeDuplicates().sink { [session, weak configure] value in
            session.configuration.maxConcurrentTasksLimit = value
            configure?.maxConcurrentTasksLimit = session.configuration.maxConcurrentTasksLimit
            configure?.save()
        }.store(in: &events)

        configure.$allowsCellularAccess.debounce(for: 0.1, scheduler: RunLoop.main).removeDuplicates().sink { [session, weak configure] value in
            session.configuration.allowsCellularAccess = value
            configure?.allowsCellularAccess = session.configuration.allowsCellularAccess
            configure?.save()
        }.store(in: &events)

        configure.$allowsExpensiveNetworkAccess.debounce(for: 0.1, scheduler: RunLoop.main).removeDuplicates().sink { [session, weak configure] value in
            session.configuration.allowsExpensiveNetworkAccess = value
            configure?.allowsExpensiveNetworkAccess = session.configuration.allowsExpensiveNetworkAccess
            configure?.save()
        }.store(in: &events)

        configure.$allowsConstrainedNetworkAccess.debounce(for: 0.1, scheduler: RunLoop.main).removeDuplicates().sink { [session, weak configure] value in
            session.configuration.allowsConstrainedNetworkAccess = value
            configure?.allowsConstrainedNetworkAccess = session.configuration.allowsConstrainedNetworkAccess
            configure?.save()
        }.store(in: &events)

        session.progress { [weak self] _ in
            self?.updateProgrss(.taskProgress)
        }.completion { [weak self] _ in
            self?.updateProgrss(.taskProgress)
        }
    }

    func createViewController() -> UIViewController & DownloadList {
        let mgr = HttpDownloadManagerViewController()
        mgr.session = self
        mgr.downloadApi = self
        return mgr
    }

    func createSettingsViewController() -> UIViewController {
        let settings = HttpDownloadManagerSettingsViewController()
        settings.session = self
        return settings
    }

    // MARK: - 操作动作

    // 添加任务
    func addTask(_ url: DownloadURLConvertible, headers: [String: String]?, fileName: String?, onMainQueue: Bool, handler: ((Task) -> Void)?) -> Task? {
        if let url = try? url.asURL() {
            return session.download(url, headers: headers, fileName: fileName, onMainQueue: onMainQueue, handler: handler)
        }
        return nil
    }

    // 暂停任务
    func pause(task: Task) {
        if let task = task as? DownloadTask {
            session.suspend(task, handler: { _ in self.updateProgrss(.taskProgress) })
        }
    }

    // 恢复任务
    public func resume(task: Task) {
        if let task = task as? DownloadTask {
            session.start(task, handler: { _ in self.updateProgrss(.taskProgress) })
        }
    }

    // 停止任务
    public func stop(task: Task) {
        if let task = task as? DownloadTask {
            session.cancel(task, handler: { _ in self.updateProgrss(.taskProgress) })
        }
    }

    // 移除任务
    func removeTask(task: Task, completely: Bool) {
        if let task = task as? DownloadTask {
            session.remove(task, completely: completely, handler: { _ in self.updateProgrss(.taskProgress) })
        }
    }

    // 暂停所有
    public func pauseAll() {
        session.totalSuspend(handler: { _ in self.updateProgrss(.allTaskPause) })
    }

    // 恢复所有
    public func resumeAll() {
        session.totalStart(handler: { _ in self.updateProgrss(.allTaskResume) })
    }

    // 停止所有
    public func stopAll() {
        session.totalCancel(handler: { _ in self.updateProgrss(.allTaskStop) })
    }

    // 移除所有
    public func removeAll() {
        session.totalRemove(handler: { _ in self.updateProgrss(.allTaskRemoved) })
    }

    // 移动任务顺序
    public func moveTask(at: Int, to: Int) {
        session.moveTask(at: at, to: to)
    }

    public func tasksSort(by: (Task, Task) throws -> Bool) {
        try? session.tasksSort(by: by)
    }

    // MARK: - 属性信息

    // 所有任务
    public var tasks: [DownloadTask] {
        return session.tasks
    }

    // 完成任务
    public var succeededTasks: [DownloadTask] {
        session.succeededTasks
    }

    // 下载速度, byte
    public var speed: Int64 {
        session.speed
    }

    // 下载速度
    public var speedString: String {
        session.speedString
    }

    // 剩余时间,秒
    public var timeRemaining: Int64 {
        session.timeRemaining
    }

    // 剩余时间
    public var timeRemainingString: String {
        session.timeRemainingString
    }

    // 进度
    public var progress: Progress {
        session.progress
    }

    // MARK: - 私有

    private func updateProgrss(_ event: Event) {
        eventPublisher.send(event)
    }

    private class Logger: Tiercel.Logable {
        init(identifier: String) {
            self.identifier = identifier
        }

        public var identifier: String = ""

        public var option: Tiercel.LogOption = .default

        public func log(_ type: Tiercel.LogType) {
            switch type {
            case let .sessionManager(_: msg, manager: manager):
                LoggerProxy.DLog(tag: "Tiercel-manager", msg: "\(manager.identifier)\n\(msg)")
            case let .downloadTask(_: msg, task: task):
                LoggerProxy.DLog(tag: "Tiercel-task", msg: "\(task.url)\n\(msg)")
            case let .error(_: msg, error: error):
                LoggerProxy.DLog(tag: "Tiercel-error", msg: "\(msg)\n\(error)")
            }
        }
    }

    private let session: Tiercel.SessionManager
    private let logger: Logger
}
