//
//  ViewController.swift
//  DownloadMamager
//
//  Created by 陈任伟 on 2022/12/16.
//

import HttpDownloadManager
import UIKit

class ViewController: UIViewController {
    @IBOutlet var contentView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let mgr = HttpDownloadManager.DefaultDownloadManager()
        let vc = mgr.createViewController()

        addChild(vc)
        if let contentView = contentView,
           let subView = vc.view {
            subView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subView)
            NSLayoutConstraint.activate([
                subView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
                subView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
                subView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
                subView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            ])
        }
    }

    @IBAction func onActonAddDownload(_ sender: AnyObject) {
        let urlString = "https://live.douyin.com/download/pc/obj/douyin-pc-client/7044145585217083655/releases/9628769/1.5.3/darwin-universal/douyin-v1.5.3-darwin-universal.dmg"
//        if let path = Bundle.main.path(forResource: "URLStrings", ofType: "plist"),
//           let urls = NSArray(contentsOfFile: path),
//           let urlString = urls.firstObject as? String,
        if let url = URL(string: urlString) {
            let name = url.lastPathComponent
            _ = HttpDownloadManager.DefaultDownloadManager().add(url, fileName: name)
        }
    }

    @IBAction func onActionBatchDownload(_ sender: AnyObject) {
        if let path = Bundle.main.path(forResource: "URLStrings", ofType: "plist"),
           let urls = NSArray(contentsOfFile: path) {
            let offset = (arc4random() % UInt32(urls.count))
            let count = (arc4random() % UInt32(urls.count)) % 30
            let urls = urls.subarray(with: NSRange(location: Int(offset), length: Int(count)))
            urls.forEach { itm in
                if let urlString = itm as? String,
                   let url = URL(string: urlString) {
                    let name = url.lastPathComponent
                    _ = HttpDownloadManager.DefaultDownloadManager().add(url, fileName: "\(name).jpg")
                }
            }
        }
    }

    @IBAction func onActionSettings() {
        navigationController?.pushViewController(HttpDownloadManager.DefaultDownloadManager().createSettingsViewController(), animated: true)
    }

    @IBAction func onActionList() {
        navigationController?.pushViewController(HttpDownloadManager.DefaultDownloadManager().createViewController(), animated: true)
    }
}
