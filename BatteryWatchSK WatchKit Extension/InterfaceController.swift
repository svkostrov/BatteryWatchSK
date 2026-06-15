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

// InterfaceController НЕ является WCSessionDelegate.
// WCSession управляется только через ExtensionDelegate.
// Новые данные iPhone приходят через Notification.Name.iPhoneDataUpdated.
class InterfaceController: WKInterfaceController {

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

    // MARK: - iPhone Data (notification from ExtensionDelegate)

    @objc func iPhoneDataReceived() {
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
        if let complications: [CLKComplication] = CLKComplicationServer.sharedInstance().activeComplications,
           !complications.isEmpty {
            for complication in complications {
                CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
            }
        }
    }

    // MARK: - Communication

    /// Отправляем на iPhone данные Watch — iPhone ответит своим зарядом через updateApplicationContext,
    /// который ExtensionDelegate примет и разошлёт уведомление .iPhoneDataUpdated.
    func sendIphoneMessage() {
        guard WCSession.default.isReachable else {
            l2.setText("Sync ❌")
            return
        }
        let message: [String: Any] = [
            "message": AwBatteryLevelString,
            "watchBattery": AwBatteryLevel,
            "watchBatteryString": AwBatteryLevelString
        ]
        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    // MARK: - Lifecycle

    override func awake(withContext context: Any?) {
        AWcheckBattery()
    }

    override func willActivate() {
        super.willActivate()
        AWcheckBattery()
        l2.setText("⌛️Sync in progress")

        // Подписываемся на обновления от ExtensionDelegate
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iPhoneDataReceived),
            name: .iPhoneDataUpdated,
            object: nil
        )

        // Сразу показываем последние известные данные из UserDefaults
        if Model.shared.hasIPhoneData {
            welcomeText.setText(Model.shared.iPhoneBatteryString)
            l2.setText("Sync ✅")
        }

        sendIphoneMessage()
    }

    override func didDeactivate() {
        super.didDeactivate()
        NotificationCenter.default.removeObserver(self)
    }

    override func didAppear() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            VersionLabel.setText("ver: \(version)")
        }
        AWcheckBattery()
        sendIphoneMessage()
    }
}
