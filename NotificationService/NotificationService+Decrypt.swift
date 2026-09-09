//
//  NotificationService+Decrypt.swift
//  NotificationService
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import Foundation
import CryptoKit

extension NotificationService {

    // MARK: - Legacy Web Push (aesgcm)
    static func decryptLegacyAESGCM(payload: Data, salt: Data, auth: Data, privateKey: P256.KeyAgreement.PrivateKey, publicKey: P256.KeyAgreement.PublicKey) -> Data? {
        guard let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: publicKey) else {
            return nil
        }
        
        let keyMaterial = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: auth, sharedInfo: Data("Content-Encoding: auth\0".utf8), outputByteCount: 32)

        let keyInfo = info(type: "aesgcm", clientPublicKey: privateKey.publicKey.x963Representation, serverPublicKey: publicKey.x963Representation)
        let key = HKDF<SHA256>.deriveKey(inputKeyMaterial: keyMaterial, salt: salt, info: keyInfo, outputByteCount: 16)

        let nonceInfo = info(type: "nonce", clientPublicKey: privateKey.publicKey.x963Representation, serverPublicKey: publicKey.x963Representation)
        let nonce = HKDF<SHA256>.deriveKey(inputKeyMaterial: keyMaterial, salt: salt, info: nonceInfo, outputByteCount: 12)

        let nonceData = nonce.withUnsafeBytes(Array.init)

        guard let sealedBox = try? AES.GCM.SealedBox(combined: nonceData + payload) else {
            return nil
        }
        
        var _plaintext: Data?
        do {
            _plaintext = try AES.GCM.open(sealedBox, using: key)
        } catch {
        }
        guard let plaintext = _plaintext else {
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
    
    // MARK: - Standard Web Push (aes128gcm)
    static func decryptAES128GCM(body: Data, auth: Data, privateKey: P256.KeyAgreement.PrivateKey) -> Data? {
        // RFC 8188 content-coding header:
        //   | salt (16) | record size (4) /*irrelevant for single-record push*/ | idlen (1) | keyid (idlen) | ciphertext... |
        // For Web Push (RFC 8291) `keyid` is the server's uncompressed P-256 public key.
        let bytes = [UInt8](body)
        let headerFixedLength = 16 /*salt*/ + 4 /*record size*/ + 1 /*idlen*/
        guard bytes.count > headerFixedLength else { return nil }

        let salt = Data(bytes[0..<16])
        let keyLength = Int(bytes[20])
        let keyStart = headerFixedLength
        let keyEnd = keyStart + keyLength
        guard bytes.count > keyEnd else { return nil }

        let serverKeyData = Data(bytes[keyStart..<keyEnd])
        let ciphertext = Data(bytes[keyEnd...])

        guard let serverPublicKey = try? P256.KeyAgreement.PublicKey(x963Representation: serverKeyData),
              let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: serverPublicKey) else {
            return nil
        }

        let clientPublicKey = privateKey.publicKey.x963Representation

        // RFC 8291 §3.4 — combine step: derive the input keying material.
        // key_info = "WebPush: info" || 0x00 || ua_public (client) || as_public (server)
        var keyInfo = Data("WebPush: info\0".utf8)
        keyInfo.append(clientPublicKey)
        keyInfo.append(serverKeyData)
        let ikm = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: auth, sharedInfo: keyInfo, outputByteCount: 32)

        // RFC 8188 §2.2 — derive the content encryption key and nonce from the salt.
        let key = HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, salt: salt, info: Data("Content-Encoding: aes128gcm\0".utf8), outputByteCount: 16)
        let nonce = HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, salt: salt, info: Data("Content-Encoding: nonce\0".utf8), outputByteCount: 12)
        let nonceData = nonce.withUnsafeBytes(Array.init)

        // AES-128-GCM: the 16-byte authentication tag is appended to the ciphertext.
        guard ciphertext.count > 16 else { return nil }
        let tag = ciphertext.suffix(16)
        let cipherOnly = ciphertext.dropLast(16)

        var _plaintext: Data?
        do {
            let sealedBox = try AES.GCM.SealedBox(nonce: try AES.GCM.Nonce(data: nonceData), ciphertext: cipherOnly, tag: tag)
            _plaintext = try AES.GCM.open(sealedBox, using: key)
        } catch {
        }
        guard let plaintext = _plaintext else {
            return nil
        }

        // RFC 8188 §2 padding: content || delimiter || 0x00... . Strip trailing padding,
        // then the final delimiter must be 0x02 for the last (here, only) record.
        var unpadded = [UInt8](plaintext)
        while unpadded.last == 0x00 {
            unpadded.removeLast()
        }
        guard unpadded.last == 0x02 else { return nil }
        unpadded.removeLast()

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
