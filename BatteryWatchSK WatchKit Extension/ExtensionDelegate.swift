//
//  ExtensionDelegate.swift
//  BatteryWatchSK WatchKit Extension
//
//  Created by Сергей Костров on 21.10.2019.
//  Copyright © 2019 Сергей Костров. All rights reserved.
//

import WatchKit
import WatchConnectivity
import ClockKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {

    func applicationDidFinishLaunching() {
        // Запускаем WCSession на уровне ExtensionDelegate — это позволяет
        // получать обновления от iPhone даже когда Watch-приложение закрыто,
        // что критично для обновления complications в фоне.
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func applicationDidBecomeActive() { }

    func applicationWillResignActive() { }

    // MARK: - WCSession Delegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

    /// Получение application context от iPhone — работает в фоне, идеально для complications.
    /// iPhone вызывает updateApplicationContext, Watch получает его даже когда оба приложения закрыты.
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let batteryLevel = applicationContext["iPhoneBattery"] as? Float {
            Model.shared.iPhoneBattery = batteryLevel
        }
        if let batteryString = applicationContext["iPhoneBatteryString"] as? String {
            Model.shared.iPhoneBatteryString = batteryString
        }
        DispatchQueue.main.async {
            self.reloadComplications()
        }
    }

    /// Получение прямого сообщения от iPhone (когда оба приложения активны).
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let batteryLevel = message["iPhoneBattery"] as? Float {
            Model.shared.iPhoneBattery = batteryLevel
        }
        if let batteryString = message["iPhoneBatteryString"] as? String {
            Model.shared.iPhoneBatteryString = batteryString
        }
        DispatchQueue.main.async {
            self.reloadComplications()
        }
    }

    // MARK: - Complications

    func reloadComplications() {
        if let complications = CLKComplicationServer.sharedInstance().activeComplications {
            for complication in complications {
                CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
                print("🔄 Complication reloaded: \(complication.family)")
            }
        }
    }

    // MARK: - Background Tasks

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Перезагружаем complications при каждом фоновом обновлении
                reloadComplications()
                // Планируем следующее обновление через 15 минут
                let nextRefresh = Date().addingTimeInterval(15 * 60)
                WKExtension.shared().scheduleBackgroundRefresh(
                    withPreferredDate: nextRefresh,
                    userInfo: nil
                ) { error in
                    if let error = error {
                        print("⚠️ Background refresh schedule error: \(error)")
                    }
                }
                backgroundTask.setTaskCompletedWithSnapshot(false)

            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: Date.distantFuture,
                    userInfo: nil
                )
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
