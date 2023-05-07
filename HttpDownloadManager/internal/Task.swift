//
//  File.swift
//
//
//  Created by 陈任伟 on 2022/12/19.
//

import Foundation
import Tiercel

extension DownloadTask: Task {
    public func completion(completionHandler: @escaping (Task) -> Void) {
        self.completion(handler: completionHandler)
    }
    
    public var taskStatus: TaskStatus {
        return TaskStatus(rawValue: status.rawValue)!
    }
}
