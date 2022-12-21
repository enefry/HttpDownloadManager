//
//  File.swift
//
//
//  Created by renwei on 2022/12/20.
//

import Foundation
import UIKit

internal class ImageLoader {
    static func load(systemName: String, name: String) -> UIImage? {
        return UIImage(systemName: systemName) ?? UIImage(named: name, in: Bundle.module, with: nil)
    }
}
