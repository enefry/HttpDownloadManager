//
//  File.swift
//
//
//  Created by 陈任伟 on 2022/12/19.
//

import Foundation
import Tiercel

let UserDefaultKeyPrefix = "com.tiercel.ui.configure"

let UserDefaultKeyTimeoutIntervalForRequest = "timeoutIntervalForRequest"
let UserDefaultKeyMaxConcurrentTasksLimit = "maxConcurrentTasksLimit"
let UserDefaultKeyAllowsExpensiveNetworkAccess = "allowsExpensiveNetworkAccess"
let UserDefaultKeyAllowsConstrainedNetworkAccess = "allowsConstrainedNetworkAccess"
let UserDefaultKeyAllowsCellularAccess = "allowsCellularAccess"

extension Configuration {
    convenience init(identifier: String, cfg: SessionConfiguration) {
        self.init(identifier: identifier)
        timeoutIntervalForRequest = cfg.timeoutIntervalForRequest
        maxConcurrentTasksLimit = cfg.maxConcurrentTasksLimit
        allowsExpensiveNetworkAccess = cfg.allowsExpensiveNetworkAccess
        allowsConstrainedNetworkAccess = cfg.allowsConstrainedNetworkAccess
        allowsCellularAccess = cfg.allowsCellularAccess
    }

    func load() {
        let userDefaults = UserDefaults.standard
        UserDefaults.standard.register(defaults: [
            "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyTimeoutIntervalForRequest)": 60,
            "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyMaxConcurrentTasksLimit)": 6,
            "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyAllowsExpensiveNetworkAccess)": true,
            "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyAllowsConstrainedNetworkAccess)": true,
            "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyAllowsCellularAccess)": true,
        ])
        timeoutIntervalForRequest = userDefaults.double(forKey: "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyTimeoutIntervalForRequest)")
        maxConcurrentTasksLimit = userDefaults.integer(forKey: "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyMaxConcurrentTasksLimit)")
        allowsExpensiveNetworkAccess = userDefaults.bool(forKey: "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyAllowsExpensiveNetworkAccess)")
        allowsConstrainedNetworkAccess = userDefaults.bool(forKey: "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyAllowsConstrainedNetworkAccess)")
        allowsCellularAccess = userDefaults.bool(forKey: "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyAllowsCellularAccess)")
    }

    func save() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(timeoutIntervalForRequest, forKey: "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyTimeoutIntervalForRequest)")
        userDefaults.set(maxConcurrentTasksLimit, forKey: "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyMaxConcurrentTasksLimit)")
        userDefaults.set(allowsExpensiveNetworkAccess, forKey: "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyAllowsExpensiveNetworkAccess)")
        userDefaults.set(allowsConstrainedNetworkAccess, forKey: "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyAllowsConstrainedNetworkAccess)")
        userDefaults.set(allowsCellularAccess, forKey: "\(UserDefaultKeyPrefix).\(identifier).\(UserDefaultKeyAllowsCellularAccess)")
    }

    func apply(cfg: inout SessionConfiguration) -> SessionConfiguration {
        cfg.timeoutIntervalForRequest = timeoutIntervalForRequest
        cfg.maxConcurrentTasksLimit = maxConcurrentTasksLimit
        cfg.allowsExpensiveNetworkAccess = allowsExpensiveNetworkAccess
        cfg.allowsConstrainedNetworkAccess = allowsConstrainedNetworkAccess
        cfg.allowsCellularAccess = allowsCellularAccess
        return cfg
    }

    func toSessionConfigure() -> SessionConfiguration {
        var cfg = SessionConfiguration()
        return apply(cfg: &cfg)
    }
}
