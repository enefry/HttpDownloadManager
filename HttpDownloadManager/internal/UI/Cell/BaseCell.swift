//
//  File.swift
//
//
//  Created by 陈任伟 on 2022/12/19.
//

import Foundation
import UIKit

class BaseCell: UICollectionViewCell {
    func createPanel() -> UIStackView {
        translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView(frame: bounds)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
        return stack
    }

    func createPair(_ buttons: [UIView]) -> UIView {
        let stackview = UIStackView(frame: CGRect(x: 0, y: 0, width: 320, height: 40))
        stackview.translatesAutoresizingMaskIntoConstraints = false
        buttons.forEach({ stackview.addArrangedSubview($0) })
        stackview.axis = .horizontal
        stackview.spacing = 8
        stackview.distribution = UIStackView.Distribution.fillEqually
        stackview.alignment = UIStackView.Alignment.fill
        return stackview
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI(stack: createPanel())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(stack: UIStackView) {
    }
}
