//
//  HttpDownloadManager.swift
//
//
//  Created by 陈任伟 on 2022/12/15.
//

import Combine
import Foundation
import UIKit

public enum DownloadError: Error, LocalizedError {
    case invalidURL(url: Any)
    public var errorDescription: String? {
        switch self {
        case let .invalidURL(url: url):
            return "URL is not valid: \(url)"
        }
    }
}

public protocol DownloadURLConvertible {
    func asURL() throws -> URL
}

extension String: DownloadURLConvertible {
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else { throw DownloadError.invalidURL(url: self) }

        return url
    }
}

extension URL: DownloadURLConvertible {
    public func asURL() throws -> URL { return self }
}

extension URLComponents: DownloadURLConvertible {
    public func asURL() throws -> URL {
        guard let url = url else { throw DownloadError.invalidURL(url: self) }

        return url
    }
}

public class Configuration {
    // 请求超时时间
    @Published public var timeoutIntervalForRequest: TimeInterval = 60.0
    // 并发数量
    @Published public var maxConcurrentTasksLimit: Int = 6
    // 是否允许蜂窝网络下载
    @Published public var allowsCellularAccess: Bool = false
    // 昂贵网络访问限制，只能在iOS 13及以上系统使用
    @Published public var allowsExpensiveNetworkAccess: Bool = true
    // 低数据网络访问限制，只能在iOS 13及以上系统使用
    @Published public var allowsConstrainedNetworkAccess: Bool = true

    let identifier: String
    public init(identifier: String) {
        self.identifier = identifier
    }
}

protocol DownloadManagerViewControllerProtocol {
    var showInformation: Bool { get set }
    var showActions: Bool { get set }
}

public enum TaskStatus: String {
    case waiting
    case running
    case suspended
    case canceled
    case failed
    case removed
    case succeeded

    case willSuspend
    case willCancel
    case willRemove
}

public protocol Task {
    var url: URL { get }
    var taskStatus: TaskStatus { get }
    var filePath: String { get }
    var fileName: String { get }
    var pathExtension: String? { get }
    var response: HTTPURLResponse? { get }
    var progress: Progress { get }
    var startDate: Double { get }
    var endDate: Double { get }
    var speed: Int64 { get }
    var timeRemaining: Int64 { get }
    var error: Error? { get }
}

public enum Event {
    case taskProgress
    case allTaskPause
    case allTaskResume
    case allTaskStop
    case allTaskRemoved
}

public protocol DownloadList {
    var swipeActionsBuilder: ((_ task: Task) -> [(UIContextualAction.Style, String, (UIViewController & DownloadList, Task) -> Void)])? { get set }
    var downloadApi: DownloadManagerApi! { get }
}

public protocol DownloadManagerApi {
    // 事件订阅
    var eventPublisher: PassthroughSubject<Event, Never> { get }

    // MARK: - UI组件

    // 创建一个列表控制器
    func createViewController() -> UIViewController & DownloadList

    // 创建一个设置配置控制器
    func createSettingsViewController() -> UIViewController

    // MARK: - 设置, 可以读取,修改

    func getConfigure() -> Configuration

    // MARK: - 路径

    // 下载数据路径 (包含临时文件,完成文件,配置文件)
    func getWorkingPath() -> String

    // 下载完成文件路径
    func getDownloadedPath() -> String

    // 下载中文件路径
    func getCachePath() -> String

    // MARK: - 操作

    // 添加任务
    func addTask(_ url: DownloadURLConvertible,
                 headers: [String: String]?,
                 fileName: String?,
                 onMainQueue: Bool,
                 handler: ((Task) -> Void)?) -> Task?
    // 暂停任务
    func pause(task: Task)
    // 恢复任务
    func resume(task: Task)
    // 停止任务
    func stop(task: Task)
    // 删除任务
    func removeTask(task: Task, completely: Bool)

    // 暂停所有
    func pauseAll()
    // 暂停所有
    func resumeAll()
    // 暂停所有
    func stopAll()
    // 暂停所有
    func removeAll()
    // 移动任务
    func moveTask(at: Int, to: Int)
    // 排序任务
    func tasksSort(by: (Task, Task) throws -> Bool)
}

extension DownloadManagerApi {
    public func add(_ url: DownloadURLConvertible,
                    headers: [String: String]? = nil,
                    fileName: String? = nil,
                    onMainQueue: Bool = true,
                    handler: ((Task) -> Void)? = nil) -> Task? {
        addTask(url, headers: headers, fileName: fileName, onMainQueue: onMainQueue, handler: handler)
    }

    public func remove(task: Task, completely: Bool = false) {
        removeTask(task: task, completely: completely)
    }
}

public func CreateDownloadManager(identifier: String) -> DownloadManagerApi {
    return HttpDownloadManagerImpl(identifier: identifier)
}

public func DefaultDownloadManager() -> DownloadManagerApi {
    return HttpDownloadManagerImpl.defaultManager
}

public func setupDefaultDownloadManagerWorkingPath(path: (String?, String?, String?)? = nil) {
    HttpDownloadManagerImpl.defaultWorkingPath = path
}
