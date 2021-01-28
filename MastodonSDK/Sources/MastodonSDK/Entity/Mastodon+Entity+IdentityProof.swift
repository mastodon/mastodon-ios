//
//  Mastodon+Entity+IdentityProof.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// IdentityProof
    ///
    /// - Since: 2.8.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/identityproof/)
    public struct IdentityProof: Codable {
        public let provider: String
        public let providerUsername: String
        public let profileURL: String
        public let proofURL: String
        public let updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case provider = "provider"
            case providerUsername = "provider_username"
            case profileURL = "profile_url"
            case proofURL = "proof_url"
            case updatedAt = "updated_at"
        }
    }
}
