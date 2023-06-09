//
//  HttpDownloadManagerViewController.swift
//
//
//  Created by 陈任伟 on 2022/12/16.
//

import Combine
import Foundation
import LoggerProxy
import Tiercel
import UIKit

fileprivate let LOGTAG = { (String(#file) as NSString).lastPathComponent }()

class HttpDownloadManagerViewController: UIViewController, DownloadManagerViewControllerProtocol, DownloadList {
    var downloadApi: DownloadManagerApi!

    var swipeActionsBuilder: ((Task) -> [(UIContextualAction.Style, String, (UIViewController & DownloadList, Task) -> Void)])?

    var showInformation: Bool = true {
        didSet {
            if isViewLoaded {
                updateUI()
            }
        }
    }

    var showActions: Bool = true {
        didSet {
            if isViewLoaded {
                updateUI()
            }
        }
    }

    var actionVersion: Int64 = 0

    struct TaskModel: Hashable, Equatable {
        static func == (lhs: HttpDownloadManagerViewController.TaskModel, rhs: HttpDownloadManagerViewController.TaskModel) -> Bool {
            return lhs.url == rhs.url
                && lhs.filePath == rhs.filePath
                && lhs.fileName == rhs.fileName
                && lhs.pathExtension == rhs.pathExtension
                && lhs.progress == rhs.progress
                && lhs.startDate == rhs.startDate
                && lhs.endDate == rhs.endDate
                && lhs.speed == rhs.speed
                && lhs.timeRemaining == rhs.timeRemaining
                && lhs.error == rhs.error
                && lhs.status == rhs.status
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(url)
            hasher.combine(filePath)
            hasher.combine(fileName)
            hasher.combine(pathExtension)
            hasher.combine(progress)
            hasher.combine(startDate)
            hasher.combine(endDate)
            hasher.combine(speed)
            hasher.combine(timeRemaining)
            hasher.combine(error)
            hasher.combine(status)
        }

        let task: Task

        let url: URL
        let filePath: String
        let fileName: String
        let pathExtension: String?
        let progress: Double
        let startDate: Double
        let endDate: Double
        let speed: Int64
        let timeRemaining: Int64
        let error: Bool
        let status: TaskStatus
        init(task: Task) {
            self.task = task
            url = task.url
            filePath = task.filePath
            fileName = task.fileName
            pathExtension = task.pathExtension
            progress = task.progress.fractionCompleted
            startDate = task.startDate
            endDate = task.endDate
            speed = task.speed
            timeRemaining = task.timeRemaining
            error = (task.error != nil)
            status = task.taskStatus
        }
    }

    enum CollectionUnionDataModel: Hashable, Equatable {
        case Info(String, String, String, String)
        case actions(Int64)
        case task(TaskModel)
    }

    enum Section {
        case info
        case actions
        case downloading
        case completed
    }

    var sessionObserver: [AnyCancellable] = []

    var session: HttpDownloadManagerImpl? {
        willSet {
            sessionObserver.forEach({ $0.cancel() })
            sessionObserver.removeAll()
        }
        didSet {
            if let session = session {
                session.eventPublisher.throttle(for: 0.3, scheduler: RunLoop.main, latest: true).sink(receiveValue: { [weak self] event in
                    print("update download event; \(event)")
                    self?.updateUI()
                }).store(in: &sessionObserver)
            }
        }
    }

    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.systemGroupedBackground
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    // MARK: - private variable

    lazy var dataSources: UICollectionViewDiffableDataSource = {
        let registration: UICollectionView.CellRegistration<TaskCell, Task> = UICollectionView.CellRegistration(handler: { cell, _, task in
            cell.action = { [weak self] task in
                self?.taskAction(task: task)
            }
            cell.bindTask(task)
        })
        let infoRegistration: UICollectionView.CellRegistration<InfoCell, (String, String, String, String)> = UICollectionView.CellRegistration(handler: { cell, _, info in
            cell.setInfo(taskInfo: info.0, speedInfo: info.1, timeInfo: info.2, progressInfo: info.3)
        })

        let actionRegistration: UICollectionView.CellRegistration<ActionCell, Int64> = UICollectionView.CellRegistration(handler: { [weak self] cell, _, _ in
            cell.session = self?.session
        })

        let datasource = UICollectionViewDiffableDataSource<Section, CollectionUnionDataModel>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case let .Info(a, b, c, d):
                return collectionView.dequeueConfiguredReusableCell(using: infoRegistration, for: indexPath, item: (a, b, c, d))
            case let .actions(idx):
                return collectionView.dequeueConfiguredReusableCell(using: actionRegistration, for: indexPath, item: idx)
            case let .task(identifier2):
                return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: identifier2.task)
            }
        }
        return datasource
    }()

    func updateUI() {
        if !isViewLoaded {
            return
        }
        if let session = session {
            var downloads: [CollectionUnionDataModel] = []
            var completed: [CollectionUnionDataModel] = []
            let tasks = session.tasks
            tasks.forEach { task in
                if task.status == .suspended ||
                    task.status == .canceled ||
                    task.status == .removed ||
                    task.status == .succeeded ||
                    task.status == .failed {
                    completed.append(CollectionUnionDataModel.task(TaskModel(task: task)))
                } else {
                    downloads.append(CollectionUnionDataModel.task(TaskModel(task: task)))
                }
            }
            var snapsnot = NSDiffableDataSourceSnapshot<Section, CollectionUnionDataModel>()
            snapsnot.appendSections([.info, .actions, .downloading, .completed])
            if showInformation {
                let succeededTasks = session.succeededTasks
                let taskInfo = "任务:\(succeededTasks.count)/\(tasks.count)"
                let speedInfo = "速度:\(session.speedString)"
                let timeInfo = "时间:\(session.timeRemainingString)"
                let progressInfo = String(format: "进度: %.2f %%", session.progress.fractionCompleted * 100.0)

                snapsnot.appendItems([CollectionUnionDataModel.Info(taskInfo, speedInfo, timeInfo, progressInfo)], toSection: .info)
            }
            if showActions {
                snapsnot.appendItems([CollectionUnionDataModel.actions(actionVersion)], toSection: .actions)
            }
            snapsnot.appendItems(downloads, toSection: .downloading)
            snapsnot.appendItems(completed, toSection: .completed)
            dataSources.apply(snapsnot)
        }
    }

    // MARK: - UI elements

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: self.createListLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    // MARK: - ui helper

    private func createListLayout() -> UICollectionViewCompositionalLayout {
        var configure = UICollectionLayoutListConfiguration(appearance: .plain)
        if #available(iOS 15.0, *) {
            configure.headerTopPadding = 8
        }
        configure.showsSeparators = true
        configure.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self = self else { return UISwipeActionsConfiguration() }
            guard let session = self.session else { return UISwipeActionsConfiguration() }
            guard let item = self.dataSources.itemIdentifier(for: indexPath) else { return UISwipeActionsConfiguration() }
            switch item {
            case let .task(task):
                var actions: [UIContextualAction] = []
                let del = UIContextualAction(style: .normal, title: "Delete") {
                    action, view, completion in
                    LoggerProxy.DLog(tag: LOGTAG, msg: "\(action) \(view) \(String(describing: completion))")
                    let alert = UIAlertController(title: "删除任务", message: "\(task.fileName)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                    alert.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { _ in
                        session.remove(task: task.task)
                    }))
                    self.present(alert, animated: true)
                    completion(false)
                }
                actions.append(del)
                if task.status == .succeeded {
                    let deleteCompletely = UIContextualAction(style: .destructive, title: "彻底删除") {
                        [weak self, task] _, _, completion in
                        if let vc = self {
                            let alert = UIAlertController(title: "彻底删除任务", message: "包括删除文件:\(task.fileName)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                            alert.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { _ in
                                vc.session?.remove(task: task.task, completely: true)
                            }))
                            vc.present(alert, animated: true)
                            completion(true)
                        }
                    }
                    actions.append(deleteCompletely)
                }
                return UISwipeActionsConfiguration(actions: actions)
            default:
                return nil
            }
        }
        configure.leadingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            var actions: [(UIContextualAction.Style, String, (UIViewController & DownloadList, Task) -> Void)] = []
            if let self = self,
               let item = self.dataSources.itemIdentifier(for: indexPath) {
                let resume: (UIViewController & DownloadList, Task) -> Void = { vc, task in
                    vc.downloadApi.resume(task: task)
                }
                let pause: (UIViewController & DownloadList, Task) -> Void = { vc, task in
                    vc.downloadApi.pause(task: task)
                }
                switch item {
                case let .task(identifier):
                    switch identifier.status {
                    case .running:
                        actions.append((UIContextualAction.Style.normal, "暂停", pause))
                    case .suspended:
                        actions.append((UIContextualAction.Style.normal, "恢复", resume))
                    case .canceled, .failed:
                        actions.append((UIContextualAction.Style.normal, "重试", resume))
                    case .waiting, .removed, .willSuspend, .willCancel, .willRemove, .succeeded:
                        break
                    }
                    if let builder = self.swipeActionsBuilder {
                        let extActs = builder(identifier.task)
                        actions.append(contentsOf: extActs)
                    }
                    if actions.count > 0 {
                        return UISwipeActionsConfiguration(actions: actions.map({ style, title, action in
                            UIContextualAction(style: style, title: title) { [action, weak self, identifier] _, _, completion in
                                if let self = self {
                                    action(self, identifier.task)
                                }
                                completion(true)
                            }
                        }))
                    }
                default:
                    break
                }
            }
            return nil
        }
        return UICollectionViewCompositionalLayout.list(using: configure)
    }
}

extension HttpDownloadManagerViewController {
    @IBAction func onActionPauseAll(_ sender: AnyObject) {
        LoggerProxy.DLog(tag: LOGTAG, msg: "pause all")
        session?.pauseAll()
    }

    @IBAction func onActionResumeAll(_ sender: AnyObject) {
        LoggerProxy.DLog(tag: LOGTAG, msg: "resume all")
        session?.resumeAll()
    }

    @IBAction func onActionStopAll(_ sender: AnyObject) {
        LoggerProxy.DLog(tag: LOGTAG, msg: "stop all")
        session?.stopAll()
    }

    @IBAction func onActionRemoveAll(_ sender: AnyObject) {
        LoggerProxy.DLog(tag: LOGTAG, msg: "remove all")
        session?.removeAll()
    }

    func taskAction(task: Task) {
        switch task.taskStatus {
        case .running:
            session?.pause(task: task)
        case .suspended, .canceled, .failed:
            session?.resume(task: task)
        case .succeeded:
            session?.remove(task: task)
        case .willRemove, .waiting, .willCancel, .willSuspend, .removed:
            break
        }
    }
}
