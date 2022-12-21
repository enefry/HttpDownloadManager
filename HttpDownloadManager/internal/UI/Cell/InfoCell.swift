//
//  File.swift
//
//
//  Created by 陈任伟 on 2022/12/19.
//

import Foundation
import UIKit

class InfoCell: BaseCell {
    private lazy var taskInfoLabel: UILabel = createLabel("任务:")
    private lazy var speedInfoLabel: UILabel = createLabel("速度:")
    private lazy var timeInfoLabel: UILabel = createLabel("时间:")
    private lazy var progressInfoLabel: UILabel = createLabel("进度:")

    override func setupUI(stack: UIStackView) {
        // 任务量
        // 总速度
        // 剩余时间
        // 总进度
        stack.addArrangedSubview(createPair([taskInfoLabel, speedInfoLabel]))
        stack.addArrangedSubview(createPair([timeInfoLabel, progressInfoLabel]))
    }

    private func createLabel(_ text: String = "") -> UILabel {
        let label = UILabel(frame: CGRect(x: 00, y: 0, width: 320, height: 28))
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        return label
    }

    public func setInfo(taskInfo: String, speedInfo: String, timeInfo: String, progressInfo: String) {
        taskInfoLabel.text = taskInfo
        speedInfoLabel.text = speedInfo
        timeInfoLabel.text = timeInfo
        progressInfoLabel.text = progressInfo
    }
}
