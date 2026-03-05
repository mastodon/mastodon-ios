// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import MastodonSDK

public enum ProfileType {
    case me(Mastodon.Entity.Account)
    case notMe(me: Mastodon.Entity.Account, displayAccount: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)
    
    var isMe: Bool {
        switch self {
        case .me:
            return true
        case .notMe:
            return false
        }
    }
    
    var accountToDisplay: Mastodon.Entity.Account {
        switch self {
        case .me(let account):
            return account
        case .notMe(_, let account, _):
            return account
        }
    }
    
    var myAccount: Mastodon.Entity.Account {
        switch self {
        case .me(let account):
            return account
        case .notMe(let myAccount, _, _):
            return myAccount
        }
    }
    
    var myRelationshipToDisplayedAccount: Mastodon.Entity.Relationship? {
        switch self {
        case .me:
            return nil
        case .notMe(_, _, let relationship):
            return relationship
        }
    }
    
    var canEditProfile: Bool {
        switch self {
        case .me: return true
        case .notMe: return false
        }
    }
}
