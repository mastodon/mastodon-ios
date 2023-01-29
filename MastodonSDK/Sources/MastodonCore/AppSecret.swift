//
//  AppSecret.swift
//  MastodonCore
//
//  Created by MainasuK Cirno on 2021-4-27.
//


import Foundation
import CryptoKit
import KeychainAccess
import MastodonCommon
import ArkanaKeys

public final class AppSecret {
    
    public static let keychain = Keychain(service: "com.emerge.mastodon.keychain", accessGroup: AppName.groupID)
    
    static let notificationPrivateKeyName = "notification-private-key-base64"
    static let notificationAuthName = "notification-auth-base64"
    
    public let notificationEndpoint: String
    
    public var notificationPrivateKey: P256.KeyAgreement.PrivateKey {
        AppSecret.createOrFetchNotificationPrivateKey()
    }
    public var notificationPublicKey: P256.KeyAgreement.PublicKey {
        notificationPrivateKey.publicKey
    }
    public var notificationAuth: Data {
        AppSecret.createOrFetchNotificationAuth()
    }
    
    public static let `default`: AppSecret = {
        return AppSecret()
    }()
    
    init() {
        #if DEBUG
        let keys = Keys.Debug()
        self.notificationEndpoint = keys.notificationEndpoint
        #else
        let keys = Keys.Release()
        self.notificationEndpoint = keys.notificationEndpoint
        #endif
    }
    
    public func register() {
        _ = AppSecret.createOrFetchNotificationPrivateKey()
        _ = AppSecret.createOrFetchNotificationAuth()
    }
    
}

extension AppSecret {
    
    private static func createOrFetchNotificationPrivateKey() -> P256.KeyAgreement.PrivateKey {
        if let encoded = AppSecret.keychain[AppSecret.notificationPrivateKeyName],
           let data = Data(base64Encoded: encoded) {
            do {
                let privateKey = try P256.KeyAgreement.PrivateKey(rawRepresentation: data)
                return privateKey
            } catch {
                assertionFailure()
                return AppSecret.resetNotificationPrivateKey()
            }
        } else {
            return AppSecret.resetNotificationPrivateKey()
        }
    }
    
    private static func resetNotificationPrivateKey() -> P256.KeyAgreement.PrivateKey {
        let privateKey = P256.KeyAgreement.PrivateKey()
        keychain[AppSecret.notificationPrivateKeyName] = privateKey.rawRepresentation.base64EncodedString()
        return privateKey
    }
    
}

extension AppSecret {
    
    private static func createOrFetchNotificationAuth() -> Data {
        if let encoded = keychain[AppSecret.notificationAuthName],
           let data = Data(base64Encoded: encoded) {
            return data
        } else {
            return AppSecret.resetNotificationAuth()
        }
    }
    
    private static func resetNotificationAuth() -> Data {
        let auth = AppSecret.createRandomAuthBytes()
        keychain[AppSecret.notificationAuthName] = auth.base64EncodedString()
        return auth
    }
    
    private static func createRandomAuthBytes() -> Data {
        let byteCount = 16
        var bytes = Data(count: byteCount)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, byteCount, $0.baseAddress!) }
        return bytes
    }
    
}
