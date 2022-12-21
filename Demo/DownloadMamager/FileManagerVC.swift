//
//  FileManagerVC.swift
//  DownloadMamager
//
//  Created by renwei on 2022/12/20.
//

import FileUIKit
import Foundation
import HttpDownloadManager
import LocalFileManager
import UIKit
class FileManagerVC: UIViewController {
    var fileManager: LocalFileManager?
    var session: FileUIKit.Session?
    override func viewDidLoad() {
        super.viewDidLoad()

        let fileManager = LocalFileManager(rootPath: HttpDownloadManager.DefaultDownloadManager().getWorkingPath())
        self.fileManager = fileManager
        let session = FileUIKit.Session(allInOne: fileManager)
        let vc = session.createDefaultFileListViewController()
        self.session = session
        addChild(vc)
        if let contentView = view,
           let subView = vc.view {
            contentView.addSubview(subView)
            NSLayoutConstraint.activate([
                subView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
                subView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
                subView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
                subView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            ])
        }
    }
}
