//
//  File.swift
//
//
//  Created by 陈任伟 on 2022/12/19.
//

import Foundation
import LoggerProxy
import UIKit

#if targetEnvironment(macCatalyst)

    public class StateBackgroundColorButton: UIButton {
        private var stateBackgroundColor: [UInt: UIColor] = [:]
        override public var isHighlighted: Bool {
            didSet {
                updateBackgroundColor()
            }
        }

        override public var isEnabled: Bool {
            didSet {
                updateBackgroundColor()
            }
        }

        override public var isSelected: Bool {
            didSet {
                updateBackgroundColor()
            }
        }

        private var lastStateColor: UIColor?
        private func updateBackgroundColor() {
            let color = stateBackgroundColor[state.rawValue] ?? stateBackgroundColor[UIButton.State.normal.rawValue]
            if color !== lastStateColor {
                backgroundColor = color
                lastStateColor = color
            }
        }

        public func setBackgroundColor(_ color: UIColor?, for state: UIButton.State) {
            stateBackgroundColor[state.rawValue] = color
            if state == self.state || state == .normal {
                updateBackgroundColor()
            }
        }
    }
#endif

fileprivate let LOGTAG = { (String(#file) as NSString).lastPathComponent }()

private func GenerateRandmoColor() -> UIColor {
    let hue = CGFloat(Double(arc4random() % 256) / 256.0) //  0.0 to 1.0
    let saturation = CGFloat((Double(arc4random() % 128) / 256.0) + 0.5) //  0.5 to 1.0, away from white
    let brightness = CGFloat((Double(arc4random() % 128) / 256.0) + 0.5) //  0.5 to 1.0, away from black
    let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    return color
}

class ActionCell: BaseCell {
    var session: HttpDownloadManagerImpl?

    private func createButton(title: String? = nil, image: UIImage? = nil, mainColor: UIColor? = nil, sel: Selector) -> UIButton {
        let tintColor = mainColor ?? UIColor.tintColor
        #if targetEnvironment(macCatalyst)
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
            button.layer.borderColor = tintColor.cgColor
            button.layer.borderWidth = 0.6
            button.layer.cornerRadius = 4
            button.layer.masksToBounds = true
            button.addConstraint(NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 32))
        #else
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
            button.configuration = .filled()

        #endif
        button.tintColor = tintColor
        button.translatesAutoresizingMaskIntoConstraints = false
        if title != nil {
            button.setTitle(title, for: .normal)
        }
        if image != nil {
            button.setImage(image, for: .normal)
        }
        button.addTarget(self, action: sel, for: .touchUpInside)
        return button
    }

    override func setupUI(stack: UIStackView) {
        stack.addArrangedSubview(createPair([pauseAllButton, resumeAllButton, stopAllButton, removeAllButton]))
    }

//    start
    private lazy var pauseAllButton: UIButton = createButton(image: ImageLoader.load(systemName: "pause.circle", name: "pause"), sel: #selector(onActionPauseAll))
    private lazy var resumeAllButton: UIButton = createButton(image: ImageLoader.load(systemName: "play.circle", name: "start"), sel: #selector(onActionResumeAll))
    private lazy var stopAllButton: UIButton = createButton(image: ImageLoader.load(systemName: "stop.circle", name: "close"), sel: #selector(onActionStopAll))
    private lazy var removeAllButton: UIButton = createButton(image: ImageLoader.load(systemName: "trash.circle.fill", name: "delete"), mainColor: UIColor.systemRed, sel: #selector(onActionRemoveAll))
}

extension ActionCell {
    func firstAvailableUIViewController() -> UIViewController? {
        var responder = next
        while responder != nil {
            if let vc = responder as? UIViewController {
                return vc
            }
            responder = responder?.next
        }
        return nil
    }

    func comfirm(title: String, comfirmAction: @escaping (HttpDownloadManagerImpl) -> Void) {
        if let session = session, session.tasks.count > 0, let vc = firstAvailableUIViewController() {
            let alert = UIAlertController(title: "\(title)所有任务", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { _ in
                comfirmAction(session)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            vc.present(alert, animated: true)
        }
    }

    @IBAction func onActionPauseAll(_ sender: AnyObject) {
        comfirm(title: "暂停") { session in
            LoggerProxy.DLog(tag: LOGTAG, msg: "pause all")
            session.pauseAll()
        }
    }

    @IBAction func onActionResumeAll(_ sender: AnyObject) {
        comfirm(title: "恢复") { session in
            LoggerProxy.DLog(tag: LOGTAG, msg: "resume all")
            session.resumeAll()
        }
    }

    @IBAction func onActionStopAll(_ sender: AnyObject) {
        comfirm(title: "停止") { session in
            LoggerProxy.DLog(tag: LOGTAG, msg: "stop all")
            session.stopAll()
        }
    }

    @IBAction func onActionRemoveAll(_ sender: AnyObject) {
        comfirm(title: "删除") { session in
            LoggerProxy.DLog(tag: LOGTAG, msg: "remove all")
            session.removeAll()
        }
    }
}
