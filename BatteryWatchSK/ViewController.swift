//
//  ViewController.swift
//  BatteryWatchSK
//
//  Created by Сергей Костров on 21.10.2019.
//  Copyright © 2019 Сергей Костров. All rights reserved.
//
import UIKit
import GoogleMobileAds
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate, GADBannerViewDelegate, GADInterstitialDelegate {

    var bannerView: GADBannerView!
    var interstitial: GADInterstitial!

    var session: WCSession!
    var IphoneBatteryLevelString: String = ""
    var IphoneBatteryLevel: Float = 0.0

    let ADMOB_APP_ID = "ca-app-pub-3377014316093239~5915687800"
    let ADMOB_Banner = "ca-app-pub-3377014316093239/1210156036"
    let ADMOB_Banner2 = "ca-app-pub-3377014316093239/8233711458"
    let ADMOB_full_screen = "ca-app-pub-3377014316093239/3721086538"

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

    /// Получаем заряд Watch от Apple Watch — отвечаем своим зарядом iPhone.
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

    func iphoneCurrentBattery() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        IphoneBatteryLevel = batteryLevel
        IphoneBatteryLevelString = "📱iPhone: " + String(format: "%.0f", Float(batteryLevel * 100)) + "%" + updateBatteryStateLabel()
        UIDevice.current.isBatteryMonitoringEnabled = false
        DispatchQueue.main.async { [self] in
            self.label1.text = self.IphoneBatteryLevelString
        }
    }

    // MARK: - Send to Watch

    /// Отправляем заряд iPhone на Watch двумя способами:
    /// 1. updateApplicationContext — работает в фоне, Watch-OS получает его даже если приложение закрыто.
    ///    Это обновляет complications без необходимости открывать приложения.
    /// 2. sendMessage — мгновенная доставка когда оба приложения активны.
    func sendWatchMessage() {
        // Структурированные данные: строка для UI + Float для complications
        let data: [String: Any] = [
            "message": IphoneBatteryLevelString,
            "iPhoneBattery": IphoneBatteryLevel,        // Float 0.0..1.0 для fillFraction
            "iPhoneBatteryString": IphoneBatteryLevelString
        ]

        // updateApplicationContext — ключевой метод для фоновых обновлений complications.
        // Последнее значение кешируется и доставляется при следующей возможности.
        do {
            try WCSession.default.updateApplicationContext(data)
            print("✅ Application context updated: \(Int(IphoneBatteryLevel * 100))%")
        } catch {
            print("⚠️ updateApplicationContext error: \(error)")
        }

        // Прямое сообщение — только когда оба приложения активны
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil)
            DispatchQueue.main.async {
                self.label3.text = "Sync 📱➡️⌚️ ✅"
            }
        } else {
            DispatchQueue.main.async {
                self.label3.text = NSLocalizedString(
                    "Sync ❌ -> Please open App on your Apple Watch",
                    comment: "Please open App on your Apple Watch"
                )
                print("⚠️ AW not reachable, context updated only")
            }
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark

        // Banner
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = ADMOB_Banner
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self

        // Interstitial
        interstitial = GADInterstitial(adUnitID: ADMOB_full_screen)
        interstitial.delegate = self
        interstitial.load(GADRequest())
        interstitial = createAndLoadInterstitial()

        iphoneCurrentBattery()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("WCSession activated, state: \(session.activationState.rawValue)")
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

    // MARK: - Ads

    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: ADMOB_full_screen)
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }

    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
    }

    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}
