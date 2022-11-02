//
//  Mastodon+Entity+ErrorDetailReason.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/1.
//

import Foundation
import MastodonSDK
import MastodonAsset
import MastodonLocalization

extension Mastodon.Entity.Error.Detail: LocalizedError {
    
    public var failureReason: String? {
        let reasons: [[String]] = [
            usernameErrorDescriptions,
            emailErrorDescriptions,
            passwordErrorDescriptions,
            agreementErrorDescriptions,
            localeErrorDescriptions,
            reasonErrorDescriptions,
        ]
        
        guard !reasons.isEmpty else {
            return nil
        }
        
        return reasons
            .flatMap { $0 }
            .joined(separator: "; ")
        
    }
    
}

extension Mastodon.Entity.Error.Detail {
    
    public enum Item: String {
        case username
        case email
        case password
        case agreement
        case locale
        case reason
        
        var localized: String {
            switch self {
            case .username:     return L10n.Scene.Register.Error.Item.username
            case .email:        return L10n.Scene.Register.Error.Item.email
            case .password:     return L10n.Scene.Register.Error.Item.password
            case .agreement:    return L10n.Scene.Register.Error.Item.agreement
            case .locale:       return L10n.Scene.Register.Error.Item.locale
            case .reason:       return L10n.Scene.Register.Error.Item.reason
            }
        }
    }
    
    private static func localizeError(item: Item, for reason: Reason) -> String {
        switch (item, reason.error) {
        case (.username, .ERR_INVALID):
            return L10n.Scene.Register.Error.Special.usernameInvalid
        case (.username, .ERR_TOO_LONG):
            return L10n.Scene.Register.Error.Special.usernameTooLong
        case (.email, .ERR_INVALID):
            return L10n.Scene.Register.Error.Special.emailInvalid
        case (.password, .ERR_TOO_SHORT):
            return L10n.Scene.Register.Error.Special.passwordTooShort
        case (_, .ERR_BLOCKED):          return L10n.Scene.Register.Error.Reason.blocked(item.localized)
        case (_, .ERR_UNREACHABLE):      return L10n.Scene.Register.Error.Reason.unreachable(item.localized)
        case (_, .ERR_TAKEN):            return L10n.Scene.Register.Error.Reason.taken(item.localized)
        case (_, .ERR_RESERVED):         return L10n.Scene.Register.Error.Reason.reserved(item.localized)
        case (_, .ERR_ACCEPTED):         return L10n.Scene.Register.Error.Reason.accepted(item.localized)
        case (_, .ERR_BLANK):            return L10n.Scene.Register.Error.Reason.blank(item.localized)
        case (_, .ERR_INVALID):          return L10n.Scene.Register.Error.Reason.invalid(item.localized)
        case (_, .ERR_TOO_LONG):         return L10n.Scene.Register.Error.Reason.tooLong(item.localized)
        case (_, .ERR_TOO_SHORT):        return L10n.Scene.Register.Error.Reason.tooShort(item.localized)
        case (_, .ERR_INCLUSION):        return L10n.Scene.Register.Error.Reason.inclusion(item.localized)
        case (_, ._other(let reason)):
            assertionFailure("Needs handle new error description here")
            return item.rawValue + " " + reason.description
        }
    }
    
    public var usernameErrorDescriptions: [String] {
        guard let username = username, !username.isEmpty else { return [] }
        return username.map { Mastodon.Entity.Error.Detail.localizeError(item: .username, for: $0) }
    }
    
    public var emailErrorDescriptions: [String] {
        guard let email = email, !email.isEmpty else { return [] }
        return email.map { Mastodon.Entity.Error.Detail.localizeError(item: .email, for: $0) }
    }
    
    public var passwordErrorDescriptions: [String] {
        guard let password = password, !password.isEmpty else { return [] }
        return password.map { Mastodon.Entity.Error.Detail.localizeError(item: .password, for: $0) }
    }
    
    public var agreementErrorDescriptions: [String] {
        guard let agreement = agreement, !agreement.isEmpty else { return [] }
        return agreement.map { Mastodon.Entity.Error.Detail.localizeError(item: .agreement, for: $0) }
    }
    
    public var localeErrorDescriptions: [String] {
        guard let locale = locale, !locale.isEmpty else { return [] }
        return locale.map { Mastodon.Entity.Error.Detail.localizeError(item: .locale, for: $0) }
    }
    
    public var reasonErrorDescriptions: [String] {
        guard let reason = reason, !reason.isEmpty else { return [] }
        return reason.map { Mastodon.Entity.Error.Detail.localizeError(item: .reason, for: $0) }
    }
}
