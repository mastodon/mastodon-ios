//
//  AppSecret.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-22.
//

import Foundation
import CryptoKit
import Keys

final class AppSecret {
    
    let notificationEndpoint: String
    
    let notificationPrivateKey: P256.KeyAgreement.PrivateKey!
    let notificationPublicKey: P256.KeyAgreement.PublicKey!
    let notificationAuth: Data
    
    static let `default`: AppSecret = {
        return AppSecret()
    }()
    
    init() {
        let keys = MastodonKeys()
        
        #if DEBUG
        self.notificationEndpoint = keys.notification_endpoint_debug
        let nonce = keys.notification_key_nonce_debug
        let auth = keys.notification_key_auth_debug
        #else
        self.notificationEndpoint = keys.notification_endpoint
        let nonce = keys.notification_key_nonce
        let auth = keys.notification_key_auth
        #endif
        
        notificationPrivateKey = try! P256.KeyAgreement.PrivateKey(rawRepresentation: Data(base64Encoded: nonce)!)
        notificationPublicKey = notificationPrivateKey!.publicKey
        notificationAuth = Data(base64Encoded: auth)!
    }
    
    var uncompressionNotificationPublicKeyData: Data {
        var data = notificationPublicKey.rawRepresentation
        if data.count == 64 {
            let prefix: [UInt8] = [0x04]
            data = Data(prefix) + data
        }
        return data
    }
    
}
