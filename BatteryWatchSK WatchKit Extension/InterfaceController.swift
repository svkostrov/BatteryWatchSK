//
//  InterfaceController.swift
//  BatteryWatchSK WatchKit Extension
//
//  Created by Сергей Костров on 21.10.2019.
//  Copyright © 2019 Сергей Костров. All rights reserved.
//
import WatchKit
import Foundation
import WatchConnectivity
import ClockKit

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet weak var VersionLabel: WKInterfaceLabel!
    @IBOutlet weak var welcomeText: WKInterfaceLabel!
    @IBOutlet weak var labAW: WKInterfaceLabel!
    @IBOutlet weak var hideButton: WKInterfaceButton!
    @IBOutlet weak var l2: WKInterfaceLabel!
    @IBOutlet weak var debugLabel: WKInterfaceLabel!

    var AwBatteryLevelString: String = ""
    var AwBatteryLevel: Float = 0.0

    // MARK: - Button Action

    @IBAction func hideWelcomeText() {
        l2.setText("Updating⌛️")
        AWcheckBattery()
        sendIphoneMessage()
    }

    // MARK: - WCSession Delegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

    /// Получаем от iPhone его заряд + запрашиваем данные в ответ.
    /// ИСПРАВЛЕНИЕ: раньше здесь сохранялся batteryAW (заряд Watch!) вместо заряда iPhone.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Читаем заряд iPhone из структурированного сообщения
        if let iPhoneBattery = message["iPhoneBattery"] as? Float {
            Model.shared.iPhoneBattery = iPhoneBattery          // ← сохраняем IPHONE battery
        }
        if let iPhoneBatteryString = message["iPhoneBatteryString"] as? String {
            Model.shared.iPhoneBatteryString = iPhoneBatteryString
        } else if let legacyMessage = message["message"] as? String {
            // Обратная совместимость со старым форматом (только строка)
            Model.shared.iPhoneBatteryString = legacyMessage
        }

        WKInterfaceDevice().play(.click)

        DispatchQueue.main.async {
            self.welcomeText.setText(Model.shared.iPhoneBatteryString)
            self.l2.setText("Sync ✅")
            self.reloadComplications()
        }
    }

    // MARK: - Watch Battery

    func updateBatteryStateLabel() -> String {
        switch WKInterfaceDevice.current().batteryState {
        case .charging: return "🔋🔌"
        default:        return "🔋"
        }
    }

    func AWcheckBattery() {
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        let batteryLevel = WKInterfaceDevice.current().batteryLevel
        AwBatteryLevel = batteryLevel
        AwBatteryLevelString = "⌚️Watch: " + String(format: "%.0f", Float(batteryLevel * 100)) + "%" + updateBatteryStateLabel()
        labAW.setText(AwBatteryLevelString)
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = false
    }

    // MARK: - Complications

    func reloadComplications() {
        if let complications: [CLKComplication] = CLKComplicationServer.sharedInstance().activeComplications {
            if complications.count > 0 {
                for complication in complications {
                    CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
                    print("🔄 Reloading complication \(complication.family.rawValue)")
                }
            } else {
                print("No active complications on watch face")
            }
        }
    }

    // MARK: - Communication

    /// Отправляем на iPhone наш заряд Watch — он ответит своим зарядом.
    func sendIphoneMessage() {
        if WCSession.default.isReachable {
            let message: [String: Any] = [
                "message": AwBatteryLevelString,
                "watchBattery": AwBatteryLevel,
                "watchBatteryString": AwBatteryLevelString
            ]
            WCSession.default.sendMessage(message, replyHandler: nil)
        } else {
            l2.setText("Sync ❌")
        }
    }

    // MARK: - Lifecycle

    override func awake(withContext context: Any?) {
        AWcheckBattery()
        sendIphoneMessage()
    }

    override func willActivate() {
        super.willActivate()
        AWcheckBattery()
        l2.setText("⌛️Sync in progress")

        if WCSession.isSupported() {
            let session = WCSession.default
            // Проверяем, чтобы не переустанавливать делегат если ExtensionDelegate уже активировал сессию
            if session.delegate == nil || !(session.delegate is InterfaceController) {
                session.delegate = self
                session.activate()
            }
            sendIphoneMessage()
        } else {
            l2.setText("Sync ❌")
        }

        // Показываем последние известные данные iPhone сразу (из UserDefaults)
        if Model.shared.hasIPhoneData {
            welcomeText.setText(Model.shared.iPhoneBatteryString)
        }
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    override func didAppear() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            VersionLabel.setText("ver: \(version)")
        }
        AWcheckBattery()
        l2.setText("⌛️Sync in progress")

        if WCSession.isSupported() {
            let session = WCSession.default
            if session.delegate == nil || !(session.delegate is InterfaceController) {
                session.delegate = self
                session.activate()
            }
            sendIphoneMessage()
        } else {
            l2.setText("Sync ❌")
        }
    }
}
