//
//  File.swift
//
//
//  Created by 陈任伟 on 2022/12/16.
//

import Foundation
import Tiercel
import UIKit

class DateFormatter {
    enum FormatType {
        case timeRemaining
        case dateFormatter
    }

    static let timeRemaining = DateFormatter(.timeRemaining)
    static let dateFormatter = DateFormatter(.dateFormatter)

    let formatterAction: (TimeInterval) -> String
    let formatter: Any
    init(_ type: FormatType) {
        switch type {
        case .timeRemaining:
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            self.formatter = formatter
            formatterAction = { value in
                if value < 60 {
                    return String(format: "%ds", Int(value))
                } else if value < 60 * 60 {
                    let min = Int(value) / 60
                    let sec = Int(value) % 60
                    return String(format: "%00dm:%00ds", min, sec)
                } else {
                    let hour = Int(value) / 3600
                    let delta = Int(value) - (hour * 60)
                    let min = delta / 60
                    let sec = delta % 60
                    return String(format: "%00dh:%00dm:%00ds", hour, min, sec)
                }
            }
        case .dateFormatter:
            let formatterHour = Foundation.DateFormatter()
            formatterHour.dateFormat = "yyyy-MM-dd HH时"
            let formatterSecond = Foundation.DateFormatter()
            formatterSecond.dateFormat = "HH:mm:ss"
            formatter = (formatterHour, formatterSecond)
            formatterAction = { value in
                let date = Date(timeIntervalSince1970: value)
                let delta = date.timeIntervalSinceNow
                if abs(delta) > 24 * 60 * 60 {
                    return formatterHour.string(from: date)
                } else {
                    return formatterSecond.string(from: date)
                }
            }
        }
    }

    func format(_ value: TimeInterval) -> String {
        return formatterAction(value)
    }
}

class TaskCell: UICollectionViewCell {
    func createLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 20))
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    func createButton() -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    func createProgress() -> UIProgressView {
        let progress = UIProgressView(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }

    fileprivate func updateUI(_ task: Task) {
        titleLabel.text = task.fileName
        bytesLabel.text = "\(task.progress.completedUnitCount.tr.convertBytesToString())/\(task.progress.totalUnitCount.tr.convertBytesToString())"
        var timeRemainingWidthPriority: UILayoutPriority = .defaultHigh
        timeRemainingLabel.text = "\(DateFormatter.timeRemaining.format(TimeInterval(task.timeRemaining)))"
        let dateString: String = {
            let prefix = "开始:\(DateFormatter.dateFormatter.format(TimeInterval(task.startDate)))"
            if task.endDate > 0 {
                return "\(prefix) ~ 结束:\(DateFormatter.dateFormatter.format(TimeInterval(task.endDate)))"
            } else if task.timeRemaining > 0 {
                return "\(prefix) ~ 预计:\(DateFormatter.dateFormatter.format(TimeInterval(Date().timeIntervalSince1970 + Double(task.timeRemaining))))"
            } else {
                return prefix
            }
        }()
        dateLabel.text = dateString
        speedLabel.text = ""

        switch task.taskStatus {
        case .suspended:
            statusLabel.text = "暂停"
        case .running:
            statusLabel.text = "下载中"
            if task.speed == 0 {
                speedLabel.text = "- KB/s"
            } else {
                speedLabel.text = "\(ByteCountFormatter.string(fromByteCount: task.speed, countStyle: .file))/s"
            }
        case .succeeded:
            statusLabel.text = "成功"
            timeRemainingLabel.text = ""
            timeRemainingWidthPriority = .defaultLow
        case .failed:
            statusLabel.text = "失败"
            timeRemainingWidthPriority = .defaultLow
        case .waiting:
            statusLabel.text = "等待中"
            timeRemainingWidthPriority = .defaultLow
        default:
            break
        }

        timeRemainingWidth.priority = timeRemainingWidthPriority
        let colors = loadStatusColor(task.taskStatus)
        statusView.backgroundColor = colors.0
        statusLabel.textColor = colors.1
    }

    func bindTask(_ task: Task) {
        biningTask = task
        progressView.observedProgress = task.progress
        updateUI(task)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            NotificationCenter.default.addObserver(self, selector: #selector(updateProgress), name: DownloadTask.runningNotification, object: nil)
        } else {
            NotificationCenter.default.removeObserver(self)
        }
    }

    @objc func updateProgress(_ notification: Notification) {
        if let task = notification.tr.downloadTask,
           let biningTask = biningTask,
           task === biningTask as AnyObject {
            DispatchQueue.main.async {
                self.updateUI(biningTask)
            }
        }
    }

    func loadStatusColor(_ status: TaskStatus) -> (UIColor, UIColor) {
        let bgName = "color.\(status.rawValue).background"
        let txtName = "color.\(status.rawValue).text"
        let bgColor = UIColor(named: bgName, in: Bundle.module, compatibleWith: nil)
        let txtColor = UIColor(named: txtName, in: Bundle.module, compatibleWith: nil)
        return (bgColor ?? UIColor.systemBackground, txtColor ?? UIColor.lightText)
    }

    lazy var titleLabel: UILabel = createLabel()
    lazy var speedLabel: UILabel = createLabel()
    lazy var bytesLabel: UILabel = createLabel()
    lazy var timeRemainingLabel: UILabel = createLabel()
    lazy var timeRemainingWidth: NSLayoutConstraint = {
        var layoutConstraint = NSLayoutConstraint(item: timeRemainingLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 100)
        layoutConstraint.priority = .defaultHigh
        return layoutConstraint
    }()

    lazy var dateLabel: UILabel = createLabel()
    lazy var statusLabel: UILabel = createLabel()
    lazy var statusView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 32))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            view.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 4),
            view.bottomAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            view.widthAnchor.constraint(equalToConstant: 13 * 3 + 5 * 2),
            view.heightAnchor.constraint(equalToConstant: 13 + 5 * 2),
        ])
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()

    lazy var progressView: UIProgressView = createProgress()

    var action: ((Task) -> Void)?
    var biningTask: Task?

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.textColor = UIColor.label
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        addSubview(titleLabel)

        timeRemainingLabel.textColor = UIColor.secondaryLabel
        timeRemainingLabel.font = UIFont.boldSystemFont(ofSize: 14)
        addSubview(timeRemainingLabel)

        dateLabel.textColor = UIColor.secondaryLabel
        dateLabel.font = UIFont.boldSystemFont(ofSize: 14)

        addSubview(dateLabel)

        bytesLabel.textColor = UIColor.secondaryLabel
        bytesLabel.font = UIFont.boldSystemFont(ofSize: 14)
        speedLabel.textColor = UIColor.secondaryLabel
        speedLabel.font = UIFont.boldSystemFont(ofSize: 14)
        bytesLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        speedLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        speedLabel.textAlignment = .right

        addSubview(bytesLabel)
        addSubview(speedLabel)

        addSubview(progressView)
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.boldSystemFont(ofSize: 12)
        addSubview(statusView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),

            timeRemainingLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            timeRemainingLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            timeRemainingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            timeRemainingWidth,

            dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            statusView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            bytesLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            bytesLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            speedLabel.trailingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: -8),
            speedLabel.topAnchor.constraint(equalTo: bytesLabel.topAnchor),
            bytesLabel.trailingAnchor.constraint(equalTo: speedLabel.leadingAnchor),

            progressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            progressView.topAnchor.constraint(equalTo: bytesLabel.bottomAnchor, constant: 8),
            progressView.trailingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: -8),

            statusView.leadingAnchor.constraint(greaterThanOrEqualTo: progressView.trailingAnchor, constant: 4),

            bottomAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 8),
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
