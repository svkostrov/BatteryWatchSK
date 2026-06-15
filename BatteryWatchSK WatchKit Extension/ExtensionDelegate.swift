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

// Уведомление для InterfaceController: пришли новые данные от iPhone.
extension Notification.Name {
    static let iPhoneDataUpdated = Notification.Name("iPhoneDataUpdated")
}

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {

    /// Задача WatchConnectivity из фона — держим ссылку до получения данных.
    private var pendingConnectivityTask: WKWatchConnectivityRefreshBackgroundTask?

    func applicationDidFinishLaunching() {
        // ExtensionDelegate — ЕДИНСТВЕННЫЙ делегат WCSession.
        // InterfaceController НЕ перехватывает делегат; он слушает уведомление .iPhoneDataUpdated.
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

    /// Получение application context от iPhone — приходит в фоне, основной канал для complications.
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyiPhoneData(applicationContext)
        // Завершаем фоновую connectivity-задачу, если она ждала этих данных.
        pendingConnectivityTask?.setTaskCompletedWithSnapshot(false)
        pendingConnectivityTask = nil
    }

    /// Получение прямого сообщения (оба приложения активны).
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        applyiPhoneData(message)
    }

    // MARK: - Data processing

    private func applyiPhoneData(_ data: [String: Any]) {
        if let batteryLevel = data["iPhoneBattery"] as? Float {
            Model.shared.iPhoneBattery = batteryLevel
        }
        if let batteryString = data["iPhoneBatteryString"] as? String {
            Model.shared.iPhoneBatteryString = batteryString
        } else if let legacyMessage = data["message"] as? String {
            Model.shared.iPhoneBatteryString = legacyMessage
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .iPhoneDataUpdated, object: nil)
            self.reloadComplications()
        }
    }

    // MARK: - Complications

    func reloadComplications() {
        guard let complications = CLKComplicationServer.sharedInstance().activeComplications,
              !complications.isEmpty else { return }
        for complication in complications {
            CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
            print("🔄 Complication reloaded: \(complication.family)")
        }
    }

    // MARK: - Background Tasks

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {

            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Держим задачу незавершённой: она закроется в didReceiveApplicationContext
                // после того как WCSession доставит ожидающий applicationContext.
                // Страховка: если didReceiveApplicationContext не придёт за 5 с — завершаем сами.
                pendingConnectivityTask = connectivityTask
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    guard let self = self, self.pendingConnectivityTask != nil else { return }
                    self.pendingConnectivityTask?.setTaskCompletedWithSnapshot(false)
                    self.pendingConnectivityTask = nil
                }

            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                reloadComplications()
                // Планируем следующее фоновое обновление через 15 минут
                WKExtension.shared().scheduleBackgroundRefresh(
                    withPreferredDate: Date().addingTimeInterval(15 * 60),
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
