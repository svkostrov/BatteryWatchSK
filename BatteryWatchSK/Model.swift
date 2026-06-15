//
//  Model.swift
//  BatteryWatchSK
//
//  Created by Сергей Костров on 08.11.2019.
//  Copyright © 2019 Сергей Костров. All rights reserved.
//

import UIKit

class Model: NSObject {
static let shared = Model()
    var LastAW:String = ""

    
    func iphoneCurrentBattery() -> String{
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false
        let bat = "📱iPhone: " + String(format: "%.0f", Float(batteryLevel * 100)) + "%🔋"
        return bat
    }
    
    
    
    
}
