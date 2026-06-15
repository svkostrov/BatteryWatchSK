//
//  BackgroundSessionService.swift
//  BatteryWatchSK
//
//  Лёгкий WCSession-хелпер для фоновых обновлений батареи.
//  Активирует сессию если нужно и шлёт updateApplicationContext.
//

import Foundation
import WatchConnectivity

final class BackgroundSessionService: NSObject, WCSessionDelegate {

    static let shared = BackgroundSessionService()
    private override init() { super.init() }

    private var pendingData: [String: Any]?
    private var completion: (() -> Void)?

    /// Отправляет данные батареи через updateApplicationContext.
    /// Активирует WCSession если ещё не активна.
    func send(data: [String: Any], completion: @escaping () -> Void) {
        guard WCSession.isSupported() else { completion(); return }
        pendingData = data
        self.completion = completion

        let session = WCSession.default
        if session.activationState == .activated {
            transmit(session)
        } else {
            session.delegate = self
            session.activate()
        }
    }

    private func transmit(_ session: WCSession) {
        if let data = pendingData {
            try? session.updateApplicationContext(data)
        }
        pendingData = nil
        completion?()
        completion = nil
    }

    private func finish() {
        completion?()
        completion = nil
        pendingData = nil
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if activationState == .activated {
            transmit(session)
        } else {
            finish()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
