// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK


public protocol AccountInfo {
    var handle: String { get }
    var avatarURL: URL? { get }
    var locked: Bool { get }
    var id: String { get }
    var fullAccount: Mastodon.Entity.Account? { get }
}

extension AccountInfo {
    func displayName(whenViewedBy myAccountID: Mastodon.Entity.Account.ID?) -> AuthorName? {
        if myAccountID == id {
            return .me
        } else {
            guard let fullAccount else { return .other(named: handle, emojis: [:]) }
            return .other(named: fullAccount.displayNameWithFallback, emojis: fullAccount.emojiMeta)
        }
    }
}

extension Mastodon.Entity.Account: AccountInfo {
    public var avatarURL: URL? { avatarImageURL() }
    public var fullAccount: Mastodon.Entity.Account? { return self }
    public var handle: String { return acct }
}

extension Mastodon.Entity.PartialAccountWithAvatar: AccountInfo {
    public var avatarURL: URL? { URL(string: avatar) }
    public var fullAccount: Mastodon.Entity.Account? { return nil }
    public var handle: String { return acct }
}
