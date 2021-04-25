//
//  NotificationService+Decrypt.swift
//  NotificationService
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import os.log
import Foundation
import CryptoKit

extension NotificationService {
    
    static func decrypt(payload: Data, salt: Data, auth: Data, privateKey: P256.KeyAgreement.PrivateKey, publicKey: P256.KeyAgreement.PublicKey) -> Data? {
        guard let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: publicKey) else {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: failed to craete shared secret", ((#file as NSString).lastPathComponent), #line, #function)
            return nil
        }
        
        let keyMaterial = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: auth, sharedInfo: Data("Content-Encoding: auth\0".utf8), outputByteCount: 32)

        let keyInfo = info(type: "aesgcm", clientPublicKey: privateKey.publicKey.x963Representation, serverPublicKey: publicKey.x963Representation)
        let key = HKDF<SHA256>.deriveKey(inputKeyMaterial: keyMaterial, salt: salt, info: keyInfo, outputByteCount: 16)

        let nonceInfo = info(type: "nonce", clientPublicKey: privateKey.publicKey.x963Representation, serverPublicKey: publicKey.x963Representation)
        let nonce = HKDF<SHA256>.deriveKey(inputKeyMaterial: keyMaterial, salt: salt, info: nonceInfo, outputByteCount: 12)

        let nonceData = nonce.withUnsafeBytes(Array.init)

        guard let sealedBox = try? AES.GCM.SealedBox(combined: nonceData + payload) else {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: failed to create sealedBox", ((#file as NSString).lastPathComponent), #line, #function)
            return nil
        }
        
        guard let plaintext = try? AES.GCM.open(sealedBox, using: key) else {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: failed to open sealedBox", ((#file as NSString).lastPathComponent), #line, #function)
            return nil
        }
        
        let paddingLength = Int(plaintext[0]) * 256 + Int(plaintext[1])
        guard plaintext.count >= 2 + paddingLength else {
            print("1")
            fatalError()
        }
        let unpadded = plaintext.suffix(from: paddingLength + 2)
        
        return Data(unpadded)
    }
    
    static private func info(type: String, clientPublicKey: Data, serverPublicKey: Data) -> Data {
        var info = Data()

        info.append("Content-Encoding: ".data(using: .utf8)!)
        info.append(type.data(using: .utf8)!)
        info.append(0)
        info.append("P-256".data(using: .utf8)!)
        info.append(0)
        info.append(0)
        info.append(65)
        info.append(clientPublicKey)
        info.append(0)
        info.append(65)
        info.append(serverPublicKey)

        return info
    }
}

extension NotificationService {
    struct MastodonNotification: Codable {
        
        private let _accessToken: String
        var accessToken: String {
            return String.normalize(base64String: _accessToken)
        }

        let notificationID: Int
        let notificationType: String
        
        let preferredLocale: String?
        let icon: String?
        let title: String
        let body: String
        
        enum CodingKeys: String, CodingKey {
            case _accessToken = "access_token"
            case notificationID = "notification_id"
            case notificationType = "notification_type"
            case preferredLocale = "preferred_locale"
            case icon
            case title
            case body
        }
        
    }
}
