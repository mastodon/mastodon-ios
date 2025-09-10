// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK

@Observable class PostInteractionSettingsViewModel {
    public var interactionSettings: (visibility: Mastodon.Entity.Status.Visibility, quotability: Mastodon.Entity.Source.QuotePolicy)
    
    public let availableVisibilities = [Mastodon.Entity.Status.Visibility.public, .unlisted, .private, .direct]
    
    init(account: Mastodon.Entity.Account?, determiningPost: Mastodon.Entity.Status?) {
        let defaultVisibility = {
            // default private when user locked
            var visibility: Mastodon.Entity.Status.Visibility = {
                guard let account else {
                    return .public
                }
                if let defaultPrivacy = account.source?.privacy, let statusPrivacy = Mastodon.Entity.Status.Visibility(rawValue: defaultPrivacy.rawValue) {
                    return statusPrivacy
                } else {
                    return account.locked ? .private : .public
                }
            }()
            // possibly override default visibility based on post being quoted or replied to
            if let visibilityOfDeterminingPost = determiningPost?.visibility {
                switch visibilityOfDeterminingPost {
                case .public:
                    // keep default
                    break
                case .unlisted:
                    if visibility == .public {
                        visibility = .unlisted
                    }
                case .private:
                    visibility = .private
                case .direct:
                    visibility = .direct
                case ._other:
                    assertionFailure()
                    break
                }
            }
            return visibility
        }()
        
        let defaultQuotability: Mastodon.Entity.Source.QuotePolicy = {
            if let specified = determiningPost?.quoteApproval?.automatic {
                return Mastodon.Entity.Source.QuotePolicy(specified)
            } else if let sourcePolicy = account?.source?.quotePolicy {
                return sourcePolicy
            } else {
                return defaultQuotePolicy(forVisibility: defaultVisibility)
            }
        }()
        
        self.interactionSettings = (defaultVisibility, defaultVisibility.allowableQuotePolicies.contains(defaultQuotability) ? defaultQuotability : defaultQuotePolicy(forVisibility: defaultVisibility))
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
    
    public func allowableQuotePolicies(forVisibility visibility: Mastodon.Entity.Status.Visibility) -> [Mastodon.Entity.Source.QuotePolicy] {
        switch visibility {
        case .public, .unlisted:
            return [.anyone, .followers, .nobody]
        default:
            return [.nobody]
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

fileprivate extension Mastodon.Entity.Status.Visibility {
    var allowableQuotePolicies: [Mastodon.Entity.Source.QuotePolicy] {
        switch self {
        case .public, .unlisted:
            return [.anyone, .followers, .nobody]
        default:
            return [.nobody]
        }
    }
}
