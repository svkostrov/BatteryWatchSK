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

    // Последнее известное состояние Apple Watch (строка от Watch-приложения)
    var LastAW: String = ""
}
