import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications

class FirebaseService: NSObject, ObservableObject {
    static let shared = FirebaseService()

    @Published var fcmToken: String?

    private var db: Firestore!

    private override init() {
        super.init()
    }

    func configure() {
        FirebaseApp.configure()
        db = Firestore.firestore()
        Messaging.messaging().delegate = self
        registerForPushNotifications()
    }

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - Sync Alerts to Firestore

    func syncAlerts(positions: [StockPosition]) {
        guard let token = fcmToken else { return }

        for pos in positions where !pos.ticker.isEmpty {
            let hasBuy = pos.desiredBuyPrice != nil
            let hasSell = pos.requiredSellPrice != nil

            let docID = "\(token)_\(pos.ticker)"

            if hasBuy || hasSell {
                var data: [String: Any] = [
                    "ticker": pos.ticker,
                    "fcmToken": token,
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                if let buy = pos.desiredBuyPrice {
                    data["buyPrice"] = buy
                }
                if let sell = pos.requiredSellPrice {
                    data["sellPrice"] = sell
                }
                db.collection("alerts").document(docID).setData(data, merge: true)
            } else {
                db.collection("alerts").document(docID).delete()
            }
        }
    }

    func removeAlert(ticker: String) {
        guard let token = fcmToken else { return }
        let docID = "\(token)_\(ticker)"
        db.collection("alerts").document(docID).delete()
    }
}

// MARK: - MessagingDelegate

extension FirebaseService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
    }
}
