//
//  File.swift
//
//
//  Created by 陈任伟 on 2022/12/19.
//

import Combine
import Foundation
import UIKit

class HttpDownloadManagerSettingsViewController: UIViewController {
    var session: DownloadManagerApi? {
        didSet {
            setupViews()
        }
    }

    func createPanel() -> UIStackView {
        let stack = UIStackView(frame: view.bounds)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
        return stack
    }

    func horizontalStack(_ buttons: [UIView]) -> UIView {
        let stackview = UIStackView(frame: CGRect(x: 0, y: 0, width: 320, height: 40))
        stackview.translatesAutoresizingMaskIntoConstraints = false
        buttons.forEach({ stackview.addArrangedSubview($0) })
        stackview.axis = .horizontal
        stackview.spacing = 8
        stackview.distribution = UIStackView.Distribution.fill
        stackview.alignment = UIStackView.Alignment.center
        return stackview
    }

    var events: [AnyCancellable] = []
    func createSwitch(title: String, getter: AnyPublisher<Bool, Never>, setter: @escaping (Bool) -> Void) -> UIView {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        let aSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
        aSwitch.translatesAutoresizingMaskIntoConstraints = false
        getter.sink { val in
            aSwitch.isOn = val
        }.store(in: &events)
        aSwitch.addAction(UIAction(handler: { action in
            if let v = action.sender as? UISwitch {
                setter(v.isOn)
            }
        }), for: .valueChanged)
        return horizontalStack([label, aSwitch])
    }

    func createSlider(title: String, getter: AnyPublisher<Float, Never>, valueRange: (Float, Float), setter: @escaping (Int) -> Void) -> UIView {
        let valueLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        valueLabel.addConstraint(NSLayoutConstraint(item: valueLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 30))
        valueLabel.textAlignment = .right
        valueLabel.font = UIFont(name: "Courier New", size: 14)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = valueRange.0
        slider.maximumValue = valueRange.1
        slider.addAction(UIAction(handler: { action in
            if let v = action.sender as? UISlider {
                setter(Int(v.value))
            }
        }), for: .valueChanged)
        getter.sink { value in
            slider.value = value
            valueLabel.text = String(format: "%d", Int(value))
        }.store(in: &events)
        slider.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        return horizontalStack([titleLabel, slider, valueLabel])
    }

    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.systemBackground
    }

    func setupViews() {
        view.subviews.forEach({ $0.removeFromSuperview() })

        if let session = session {
            let configure = session.getConfigure()
            let stack = createPanel()
            stack.addArrangedSubview(createSlider(title: "超时时间:", getter: configure.$timeoutIntervalForRequest.removeDuplicates().map({ time in
                Float(time)
            }).eraseToAnyPublisher(), valueRange: (0, 180), setter: { value in
                configure.timeoutIntervalForRequest = TimeInterval(value)
            }))
            stack.addArrangedSubview(createSlider(title: "超时时间:", getter: configure.$maxConcurrentTasksLimit.removeDuplicates().map({ time in
                Float(time)
            }).eraseToAnyPublisher(), valueRange: (0, 6), setter: { value in
                configure.maxConcurrentTasksLimit = value
            }))
            stack.addArrangedSubview(createSwitch(title: "蜂窝网络:", getter: configure.$allowsCellularAccess.eraseToAnyPublisher(), setter: { val in
                configure.allowsCellularAccess = val
            }))
            stack.addArrangedSubview(createSwitch(title: "昂贵网络:", getter: configure.$allowsExpensiveNetworkAccess.eraseToAnyPublisher(), setter: { val in
                configure.allowsExpensiveNetworkAccess = val
            }))
            stack.addArrangedSubview(createSwitch(title: "低数据网络:", getter: configure.$allowsConstrainedNetworkAccess.eraseToAnyPublisher(), setter: { val in
                configure.allowsConstrainedNetworkAccess = val
            }))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
