//
//  Model.swift
//  BatteryWatchSK WatchKit Extension
//
//  Created by Сергей Костров on 22.10.2019.
//  Copyright © 2019 Сергей Костров. All rights reserved.
//

import WatchKit

class Model: NSObject {
    static let shared = Model()

    // Заряд Apple Watch (in-memory, читается прямо с девайса)
    var batteryAW: Float = 1.0
    var inc = 0

    // Заряд iPhone — персистентно через UserDefaults
    // Значение сохраняется между запусками extension (нужно для complications)
    var iPhoneBattery: Float {
        get { return UserDefaults.standard.float(forKey: "iPhoneBatteryLevel") }
        set { UserDefaults.standard.set(newValue, forKey: "iPhoneBatteryLevel") }
    }

    var iPhoneBatteryString: String {
        get { return UserDefaults.standard.string(forKey: "iPhoneBatteryString") ?? "📱--%" }
        set { UserDefaults.standard.set(newValue, forKey: "iPhoneBatteryString") }
    }

    // true если данные уже получены хотя бы раз
    var hasIPhoneData: Bool {
        return UserDefaults.standard.object(forKey: "iPhoneBatteryLevel") != nil
    }
}
