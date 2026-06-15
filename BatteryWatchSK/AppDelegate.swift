//
//  AppDelegate.swift
//  BatteryWatchSK
//
//  Created by Сергей Костров on 21.10.2019.
//  Copyright © 2019 Сергей Костров. All rights reserved.
//

import UIKit
import BackgroundTasks

private let kBGRefreshTaskID = "com.rokot.BatteryWatchSK.refresh"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Регистрируем фоновую задачу обновления батареи
        BGTaskScheduler.shared.register(forTaskWithIdentifier: kBGRefreshTaskID, using: nil) { [weak self] task in
            self?.handleBatteryRefresh(task: task as! BGAppRefreshTask)
        }

        scheduleBackgroundRefresh()

        let icon = UIApplicationShortcutIcon(type: .cloud)
        let item = UIApplicationShortcutItem(type: "com.yoursite.yourapp.adduser",
                                             localizedTitle: "📱🙂⌚️",
                                             localizedSubtitle: Model.shared.LastAW,
                                             icon: icon, userInfo: nil)
        UIApplication.shared.shortcutItems = [item]
        return true
    }

    // Перепланируем при уходе в фон
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleBackgroundRefresh()
    }

    // MARK: - Background Refresh

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: kBGRefreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // не раньше чем через 15 минут
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleBatteryRefresh(task: BGAppRefreshTask) {
        // Планируем следующий запуск сразу
        scheduleBackgroundRefresh()

        // Если iOS прерывает задачу — завершаем корректно
        task.expirationHandler = { task.setTaskCompleted(success: false) }

        // Читаем уровень заряда
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        UIDevice.current.isBatteryMonitoringEnabled = false

        guard level >= 0 else {
            task.setTaskCompleted(success: false)
            return
        }

        let stateEmoji: String
        switch state {
        case .charging: stateEmoji = "🔌"
        case .full:     stateEmoji = "🔋✅"
        default:        stateEmoji = "🔋"
        }

        let batteryString = "📱iPhone: \(Int(level * 100))%\(stateEmoji)"
        let data: [String: Any] = [
            "message":             batteryString,
            "iPhoneBattery":       level,
            "iPhoneBatteryString": batteryString
        ]

        // Шлём на Watch и завершаем задачу
        BackgroundSessionService.shared.send(data: data) {
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Scene lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}
