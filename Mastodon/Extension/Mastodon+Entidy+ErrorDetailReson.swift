//
//  Mastodon+Entidy+ErrorDetailReason.swift
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
        if let username = self.username {
            if !username.isEmpty {
                let errors = username.map {
                    L10n.Common.Errors.Item.username + " " + $0.localizedDescription()
                }
                messages.append(contentsOf: errors)
            }
        }
        if let email = self.email {
            if !email.isEmpty {
                let errors = email.map {
                    L10n.Common.Errors.Item.email + " " + $0.localizedDescription()
                }
                messages.append(contentsOf: errors)
            }
        }
        if let password = self.password {
            if !password.isEmpty {
                let errors = password.map {
                    L10n.Common.Errors.Item.password + " " + $0.localizedDescription()
                }
                messages.append(contentsOf: errors)
            }
        }
        if let agreement = self.agreement {
            if !agreement.isEmpty {
                let errors = agreement.map {
                    L10n.Common.Errors.Item.agreement + " " + $0.localizedDescription()
                }
                messages.append(contentsOf: errors)
            }
        }
        if let locale = self.locale {
            if !locale.isEmpty {
                let errors = locale.map {
                    L10n.Common.Errors.Item.locale + " " + $0.localizedDescription()
                }
                messages.append(contentsOf: errors)
            }
        }
        if let reason = self.reason {
            if !reason.isEmpty {
                let errors = reason.map {
                    L10n.Common.Errors.Item.reason + " " + $0.localizedDescription()
                }
                messages.append(contentsOf: errors)
            }
        }
        let message = messages
            .compactMap { $0 }
            .joined(separator: ", ")
        return message
    }
}
