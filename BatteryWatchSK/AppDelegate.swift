//
//  AppDelegate.swift
//  BatteryWatchSK
//
//  Created by Сергей Костров on 21.10.2019.
//  Copyright © 2019 Сергей Костров. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let icon = UIApplicationShortcutIcon(type: .cloud)
        let item = UIApplicationShortcutItem(type: "com.yoursite.yourapp.adduser", localizedTitle: "📱🙂⌚️", localizedSubtitle: Model.shared.LastAW, icon: icon, userInfo: nil)
        UIApplication.shared.shortcutItems = [item]
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) { }
}
