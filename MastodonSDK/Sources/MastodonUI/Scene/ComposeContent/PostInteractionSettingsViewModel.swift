// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK

@Observable public class PostInteractionSettingsViewModel {
    
    public enum InitialSettings {
        case fresh(replyingToVisibility: Mastodon.Entity.Status.Visibility?)  // default visibility depends on the replyTo's visibility
        case editing(visibility: Mastodon.Entity.Status.Visibility, quotability: Mastodon.Entity.Source.QuotePolicy)  // visibility choice is fixed, but quotability can be changed
        
        public func defaultSettings(forAuthor account: Mastodon.Entity.Account?) -> (visibility: Mastodon.Entity.Status.Visibility, quotability: Mastodon.Entity.Source.QuotePolicy) {
            switch self {
            case .fresh(let replyingToVisibility):
                let _visibility = {
                    let authorDefault = defaultVisibility(forAuthor: account)
                    if let replyingToVisibility, replyingToVisibility.isMoreRestrictive(than: authorDefault) {
                        return replyingToVisibility
                    } else {
                        return authorDefault
                    }
                }()
                let _quotability = {
                   let authorDefault = defaultQuotability(forAuthor: account)
                    let allowableQuotabilities = _visibility.allowableQuotePolicies
                    if allowableQuotabilities.contains(authorDefault) {
                        return authorDefault
                    } else {
                        return defaultQuotePolicy(forVisibility: _visibility)
                    }
                }()
                return (_visibility, _quotability)
            case .editing(let visibility, let quotability):
                return (visibility, quotability)
            }
        }
        
        func defaultVisibility(forAuthor account: Mastodon.Entity.Account?) -> Mastodon.Entity.Status.Visibility {
            guard let account else {
                return .public
            }
            if let defaultPrivacy = account.source?.privacy, let statusPrivacy = Mastodon.Entity.Status.Visibility(rawValue: defaultPrivacy.rawValue) {
                return statusPrivacy
            } else {
                // default private if account is locked (manually approves new follows)
                return account.locked ? .private : .public
            }
        }
        
        func defaultQuotability(forAuthor account: Mastodon.Entity.Account?) -> Mastodon.Entity.Source.QuotePolicy {
            guard let account else {
                return .anyone
            }
            if let defaultSetting = account.source?.quotePolicy {
                return defaultSetting
            } else {
                // default no quotes if account is locked (manually approves new follows)
                return account.locked ? .nobody : .anyone
            }
        }
        
        var visibilityOptions: [Mastodon.Entity.Status.Visibility] {
            switch self {
            case .editing(let visibility, _):
                return [visibility]
            case .fresh(let replyingToVisibility):
                switch replyingToVisibility {
                case .direct:
                    return [.direct]
                default:
                    return [.public, .unlisted, .private, .direct]
                }
            }
        }
        
        var canEditVisibility: Bool {
            switch self {
            case .editing: false
            case .fresh: true
            }
        }
    }
    
    public var interactionSettings: (visibility: Mastodon.Entity.Status.Visibility, quotability: Mastodon.Entity.Source.QuotePolicy)
    public var canEditVisibility: Bool
    
    public let availableVisibilities: [Mastodon.Entity.Status.Visibility]
    
    public init(account: Mastodon.Entity.Account?, initialSettings: InitialSettings) {
        self.canEditVisibility = initialSettings.canEditVisibility
        self.availableVisibilities = initialSettings.visibilityOptions
        interactionSettings = initialSettings.defaultSettings(forAuthor: account)
    }
    
    public func setInteractionSettings(visibility: Mastodon.Entity.Status.Visibility?, quotability: Mastodon.Entity.Source.QuotePolicy?) {
        guard visibility != interactionSettings.visibility || quotability != interactionSettings.quotability else { return }
        
        let newVisibility = visibility ?? interactionSettings.visibility
        let requestedQuotability = quotability ?? interactionSettings.quotability
        if newVisibility.allowableQuotePolicies.contains(requestedQuotability) {
            interactionSettings = (newVisibility, requestedQuotability)
        } else {
            interactionSettings = (newVisibility, .nobody)
        }
    }
}

fileprivate func defaultQuotePolicy(forVisibility visibility: Mastodon.Entity.Status.Visibility) -> Mastodon.Entity.Source.QuotePolicy {
    switch visibility {
    case .public:
        return .anyone
    case .unlisted:
        return .followers
    case .direct:
        return .nobody
    case .private:
        return .nobody
    default:
        return .anyone
    }
}

fileprivate extension Mastodon.Entity.Source.QuotePolicy {
    init(_ automaticallyApproved: [Mastodon.Entity.Status.QuotePermissionUserCategory]) {
        if automaticallyApproved.contains(.anyone) {
            self = .anyone
        } else if automaticallyApproved.contains(.followersOnly) {
            self = .followers
        } else {
            self = .nobody
        }
    }
}

extension Mastodon.Entity.Status.Visibility {
    public var allowableQuotePolicies: [Mastodon.Entity.Source.QuotePolicy] {
        switch self {
        case .public, .unlisted:
            return [.anyone, .followers, .nobody]
        default:
            return [.nobody]
        }
    }
}

extension Mastodon.Entity.Status.Visibility {
    func isMoreRestrictive(than other: Mastodon.Entity.Status.Visibility) -> Bool {
        switch self {
        case .public:
            return false
        case .unlisted:
            return other == .public
        case .private:
            return other == .public || other == .direct
        case .direct:
            return other != .direct
        default:
            assertionFailure("unrecognized visibility setting")
            return false
        }
    }
}

extension Mastodon.Entity.Status {
    public var specifiedQuotePolicyOrNobody: Mastodon.Entity.Source.QuotePolicy {
        guard let automaticApprovals = quoteApproval?.automatic else { return .nobody }
        if automaticApprovals.contains(.anyone) {
            return .anyone
        } else if automaticApprovals.contains(.followersOnly) {
            return .followers
        } else {
            return .nobody
        }
    }
}
