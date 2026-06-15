//
//  ViewController.swift
//  BatteryWatchSK
//
//  Created by Сергей Костров on 21.10.2019.
//  Copyright © 2019 Сергей Костров. All rights reserved.
//
import UIKit
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate {

    var IphoneBatteryLevelString: String = ""
    var IphoneBatteryLevel: Float = 0.0

    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var pb1: UIProgressView!

    @IBAction func Help(_ sender: UIButton) { }

    // MARK: - WCSession Delegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let watchMessage = message["message"] as? String ?? ""
        print("📨 Данные от Watch: \(watchMessage). Отправляю данные iPhone.")
        iphoneCurrentBattery()
        sendWatchMessage()

        DispatchQueue.main.async {
            self.label2.text = watchMessage
            self.label3.text = "Sync 📱⌚️ ✅"
        }
        Model.shared.LastAW = watchMessage
    }

    // MARK: - Battery

    func updateBatteryStateLabel() -> String {
        switch UIDevice.current.batteryState {
        case .charging: return "🔌"
        case .full:     return "🔋✅"
        default:        return "🔋"
        }
    }

    /// Читаем текущий заряд. isBatteryMonitoringEnabled включён в viewDidLoad и остаётся включённым.
    func iphoneCurrentBattery() {
        let level = UIDevice.current.batteryLevel
        guard level >= 0 else { return }  // -1.0 если мониторинг отключён
        IphoneBatteryLevel = level
        IphoneBatteryLevelString = "📱iPhone: " + String(format: "%.0f", level * 100) + "%" + updateBatteryStateLabel()
        DispatchQueue.main.async {
            self.label1.text = self.IphoneBatteryLevelString
        }
    }

    /// Вызывается автоматически при изменении заряда или состояния зарядки.
    @objc func batteryLevelDidChange() {
        iphoneCurrentBattery()
        sendWatchMessage()
    }

    // MARK: - Send to Watch

    func sendWatchMessage() {
        let data: [String: Any] = [
            "message": IphoneBatteryLevelString,
            "iPhoneBattery": IphoneBatteryLevel,
            "iPhoneBatteryString": IphoneBatteryLevelString
        ]

        do {
            try WCSession.default.updateApplicationContext(data)
        } catch {
            print("⚠️ updateApplicationContext error: \(error)")
        }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil)
            DispatchQueue.main.async { self.label3.text = "Sync 📱➡️⌚️ ✅" }
        } else {
            DispatchQueue.main.async {
                self.label3.text = NSLocalizedString(
                    "Sync ❌ -> Please open App on your Apple Watch",
                    comment: "Please open App on your Apple Watch"
                )
            }
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark

        // Включаем мониторинг один раз — оставляем включённым на время жизни VC.
        // Это позволяет получать актуальные значения и события об изменении заряда.
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )

        iphoneCurrentBattery()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            label2.text = ""
            label3.text = ""
            sendWatchMessage()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        iphoneCurrentBattery()
        sendWatchMessage()
    }

    deinit {
        UIDevice.current.isBatteryMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self)
    }
}
