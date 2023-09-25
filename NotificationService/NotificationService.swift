//
//  NotificationService.swift
//  NotificationService
//
//  Created by MainasuK Cirno on 2021-4-23.
//

import UserNotifications
import CryptoKit
import AlamofireImage
import MastodonCore

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...

            let privateKey = AppSecret.default.notificationPrivateKey
            let auth = AppSecret.default.notificationAuth
            
            guard let encodedPayload = bestAttemptContent.userInfo["p"] as? String else {
                contentHandler(bestAttemptContent)
                return
            }
            let payload = encodedPayload.decode85()
            
            guard let encodedPublicKey = bestAttemptContent.userInfo["k"] as? String,
                  let publicKey = NotificationService.publicKey(encodedPublicKey: encodedPublicKey) else {
                contentHandler(bestAttemptContent)
                return
            }
            
            guard let encodedSalt = bestAttemptContent.userInfo["s"] as? String else {
                contentHandler(bestAttemptContent)
                return
            }
            let salt = encodedSalt.decode85()

            guard let plaintextData = NotificationService.decrypt(payload: payload, salt: salt, auth: auth, privateKey: privateKey, publicKey: publicKey),
                  let notification = try? JSONDecoder().decode(MastodonPushNotification.self, from: plaintextData) else {
                contentHandler(bestAttemptContent)
                return
            }
            
            bestAttemptContent.title = notification.title
            bestAttemptContent.subtitle = ""
            bestAttemptContent.body = notification.body.escape()
            bestAttemptContent.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: "BoopSound.caf"))
            bestAttemptContent.userInfo["plaintext"] = plaintextData
            
            let accessToken = notification.accessToken
            UserDefaults.shared.increaseNotificationCount(accessToken: accessToken)
            
            UserDefaults.shared.notificationBadgeCount += 1
            bestAttemptContent.badge = NSNumber(integerLiteral: UserDefaults.shared.notificationBadgeCount)
            
            if let urlString = notification.icon, let url = URL(string: urlString) {
                let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("notification-attachments")
                try? FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                let filename = url.lastPathComponent
                let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)

                ImageDownloader.default.download(URLRequest(url: url), completion: { [weak self] response in
                    guard let _ = self else { return }
                    switch response.result {
                    case .failure(_):
                        break
                    case .success(let image):
                        try? image.pngData()?.write(to: fileURL)
                        if let attachment = try? UNNotificationAttachment(identifier: filename, url: fileURL, options: nil) {
                            bestAttemptContent.attachments = [attachment]
                        }
                    }
                    contentHandler(bestAttemptContent)
                })
            } else {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

extension NotificationService {
    static func publicKey(encodedPublicKey: String) -> P256.KeyAgreement.PublicKey? {
        let publicKeyData = encodedPublicKey.decode85()
        return try? P256.KeyAgreement.PublicKey(x963Representation: publicKeyData)
    }
}

extension String {
    func escape() -> String {
        return self
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "’")

    }
}
