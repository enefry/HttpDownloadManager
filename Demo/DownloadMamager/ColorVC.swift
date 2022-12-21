//
//  ColorVC.swift
//  DownloadMamager
//
//  Created by renwei on 2022/12/20.
//

import Foundation
import UIKit
class ColorVC: UIViewController {
    @IBOutlet var stack: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()

        let names = ["canceled",
                     "failed",
                     "removed",
                     "running",
                     "succeeded",
                     "suspended",
                     "waiting"]
        for idx in 0 ..< names.count {
            let name = names[idx]
            let view = stack.arrangedSubviews[idx]
            let label = view.subviews.first as? UILabel
            let bgName = "color.\(name).background"
            let txtName = "color.\(name).text"
            let bgColor = UIColor(named: bgName, in: Bundle.main, compatibleWith: nil)
            let txtColor = UIColor(named: txtName, in: Bundle.main, compatibleWith: nil)
            view.backgroundColor = bgColor
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            label?.text = name
            label?.textColor = txtColor
        }
    }
}
