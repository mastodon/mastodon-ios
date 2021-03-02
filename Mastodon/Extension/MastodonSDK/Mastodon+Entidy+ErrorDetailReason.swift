//
//  Mastodon+Entity+ErrorDetailReason.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/1.
//

import MastodonSDK

extension Mastodon.Entity.ErrorDetailReason {
    func localizedDescription() -> String {
        switch self.error {
        case .ERR_BLOCKED:
            return L10n.Common.Errors.errBlocked
        case .ERR_UNREACHABLE:
            return L10n.Common.Errors.errUnreachable
        case .ERR_TAKEN:
            return L10n.Common.Errors.errTaken
        case .ERR_RESERVED:
            return L10n.Common.Errors.errReserved
        case .ERR_ACCEPTED:
            return L10n.Common.Errors.errAccepted
        case .ERR_BLANK:
            return L10n.Common.Errors.errBlank
        case .ERR_INVALID:
            return L10n.Common.Errors.errInvalid
        case .ERR_TOO_LONG:
            return L10n.Common.Errors.errTooLong
        case .ERR_TOO_SHORT:
            return L10n.Common.Errors.errTooShort
        case .ERR_INCLUSION:
            return L10n.Common.Errors.errInclusion
        case ._other:
            return self.errorDescription ?? ""
        }
    }
}

extension Mastodon.Entity.ErrorDetail {
    func localizedDescription() -> String {
        var messages: [String?] = []

        if let username = self.username, !username.isEmpty {
            let errors = username.map { errorDetailReason -> String in
                switch errorDetailReason.error {
                case .ERR_INVALID:
                    return L10n.Common.Errors.Itemdetail.usernameInvalid
                case .ERR_TOO_LONG:
                    return L10n.Common.Errors.Itemdetail.usernameTooLong
                default:
                    return L10n.Common.Errors.Item.username + " " + errorDetailReason.localizedDescription()
                }
            }
            messages.append(contentsOf: errors)
        }

        if let email = self.email, !email.isEmpty {
            let errors = email.map { errorDetailReason -> String in
                if errorDetailReason.error == .ERR_INVALID {
                    return L10n.Common.Errors.Itemdetail.emailInvalid
                } else {
                    return L10n.Common.Errors.Item.email + " " + errorDetailReason.localizedDescription()
                }
            }
            messages.append(contentsOf: errors)
        }
        if let password = self.password,!password.isEmpty {
            let errors = password.map { errorDetailReason -> String in
                if errorDetailReason.error == .ERR_TOO_SHORT {
                    return L10n.Common.Errors.Itemdetail.passwordTooShrot
                } else {
                    return L10n.Common.Errors.Item.password + " " + errorDetailReason.localizedDescription()
                }
            }
            messages.append(contentsOf: errors)
        }
        if let agreement = self.agreement, !agreement.isEmpty {
            let errors = agreement.map {
                L10n.Common.Errors.Item.agreement + " " + $0.localizedDescription()
            }
            messages.append(contentsOf: errors)
        }
        if let locale = self.locale, !locale.isEmpty {
            let errors = locale.map {
                L10n.Common.Errors.Item.locale + " " + $0.localizedDescription()
            }
            messages.append(contentsOf: errors)
        }
        if let reason = self.reason, !reason.isEmpty {
            let errors = reason.map {
                L10n.Common.Errors.Item.reason + " " + $0.localizedDescription()
            }
            messages.append(contentsOf: errors)
        }
        let message = messages
            .compactMap { $0 }
            .joined(separator: ", ")
        return message.capitalizingFirstLetter()
    }
}
