// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonSDK

public struct MastodonAccount: Identifiable, Codable {
    public let id: Mastodon.Entity.Account.ID
    let metadata: MetaData
    let displayInfo: DisplayInfo
    let metrics: Metrics
    let bioForDisplay: String
    let bioForEdit: String?
    let _legacyEntity: Mastodon.Entity.Account
}

struct ImageUrl: Codable {
    private let animatedUrl: URL?
    private let staticUrl: URL

    init?(
        potentiallyAnimated: String?, definitelyStatic: String?, fallback: URL?
    ) {
        let animatedUrl: URL? = {
            guard let potentiallyAnimated else { return nil }
            return URL(string: potentiallyAnimated)
        }()
        let staticUrl: URL? = {
            guard let definitelyStatic else { return fallback }
            return URL(string: definitelyStatic) ?? fallback
        }()

        guard let staticUrl else { return nil }

        if animatedUrl == staticUrl {
            self.staticUrl = staticUrl
            self.animatedUrl = nil
        } else {
            self.animatedUrl = animatedUrl
            self.staticUrl = staticUrl
        }
    }

    var preferredUrl: URL {
        if UserDefaults.standard.preferredStaticAvatar {
            return staticUrl
        } else {
            return animatedUrl ?? staticUrl
        }
    }
}

extension MastodonAccount {
    struct MetaData: Codable {
        let profileUrl: URL?
        let createdAt: Date
        let manuallyApprovesNewFollows: Bool
        let verifiedLink: String?
        let customFieldsForDisplay: [Mastodon.Entity.Field]?
        let customFieldsForEdit: [Mastodon.Entity.Field]?
        let isBot: Bool
        let showsFeaturedTab: Bool
        let showsMediaTab: Bool
        let mediaTabIncludesReplies: Bool
    }
}

extension MastodonAccount {
    struct DisplayInfo: Codable {
        let fullHandle: String
        let displayName: String
        let emojis: [Mastodon.Entity.Emoji]
        private let avatarImage: ImageUrl
        private let headerImage: ImageUrl?

        var avatarUrl: URL {
            return avatarImage.preferredUrl
        }

        var bannerImageUrl: URL? {
            return headerImage?.preferredUrl
        }
    }
    
    struct Metrics: Codable {
        let postCount: Int
        let followersCount: Int
        let followingCount: Int
    }
}

protocol FromAccountEntityDerivable {
    static func fromEntity(
        _ entity: Mastodon.Entity.Account,
        authenticatedDomain: String
    ) -> Self
}

extension MastodonAccount: FromAccountEntityDerivable {
    static func fromEntity(
        _ entity: Mastodon.Entity.Account,
        authenticatedDomain: String
    ) -> Self {
        return MastodonAccount(
            id: entity.id,
            metadata: MetaData.fromEntity(entity, authenticatedDomain: authenticatedDomain),
            displayInfo: DisplayInfo.fromEntity(
                entity, authenticatedDomain: authenticatedDomain),
            metrics: Metrics.fromEntity(entity, authenticatedDomain: authenticatedDomain),
            bioForDisplay: entity.note,
            bioForEdit: entity.source?.note,
            _legacyEntity: entity
        )
    }
}

extension MastodonAccount.MetaData: FromAccountEntityDerivable {
    static func fromEntity(_ entity: Mastodon.Entity.Account, authenticatedDomain: String) -> MastodonAccount.MetaData {
        return MastodonAccount.MetaData(profileUrl: URL(string: entity.url), createdAt: entity.createdAt, manuallyApprovesNewFollows: entity.locked, verifiedLink: entity.verifiedLink?.value, customFieldsForDisplay: entity.fields, customFieldsForEdit: entity.source?.fields, isBot: entity.bot ?? false, showsFeaturedTab: true, showsMediaTab: true, mediaTabIncludesReplies: true)
        // TODO: get real values for media and featured tab settings (available if the api version >= 8)
    }
}

extension MastodonAccount.DisplayInfo: FromAccountEntityDerivable {
    static func fromEntity(
        _ entity: Mastodon.Entity.Account,
        authenticatedDomain: String
    ) -> Self {
        let avatarImage = ImageUrl(
            potentiallyAnimated: entity.avatar,
            definitelyStatic: entity.avatarStatic,
            fallback: fallbackAvatarURL(
                fromCurrentUserDomain: "mastodon.social"))!
        let headerImage = ImageUrl(
            potentiallyAnimated: entity.header,
            definitelyStatic: entity.headerStatic,
            fallback: nil)
        let fullHandle: String = {
            let acctSplitOnAt = entity.acct.split(separator: "@")
            if acctSplitOnAt.count == 1 {
                return entity.acct + "@" + authenticatedDomain
            } else {
                return entity.acct
            }
        }()
        
        let escapedDisplayName = escapeHtml(entity.displayNameWithFallback)
        return Self(
            fullHandle: fullHandle, displayName: escapedDisplayName,
            emojis: entity.emojis, avatarImage: avatarImage,
            headerImage: headerImage)
    }
}

extension MastodonAccount.Metrics: FromAccountEntityDerivable {
    static func fromEntity(_ entity: Mastodon.Entity.Account, authenticatedDomain: String) -> Self {
        Self(postCount: entity.statusesCount, followersCount: entity.followersCount, followingCount: entity.followingCount)
    }
}

func fallbackAvatarURL(fromCurrentUserDomain domain: String) -> URL {
    let missingImageName = "missing.png"
    return URL(
        string: "https://\(domain)/avatars/original/\(missingImageName)")!
}


extension MastodonAccount {
    enum Relationship: Codable {
        case isMe
        case isNotMe(RelationshipInfo?)
        
        var info: RelationshipInfo? {
            switch self {
            case .isMe:
                return nil
            case .isNotMe(let info):
                return info
            }
        }

        func refersToSameAccount(as otherRelationship: Self) -> Bool {
            switch (self, otherRelationship) {
            case (.isMe, .isMe):
                return true
            case (.isNotMe(let firstInfo), .isNotMe(let secondInfo)):
                guard let firstInfo, let secondInfo else { return false }
                return firstInfo.id == secondInfo.id
            default:
                return false
            }
        }
        
        func byUpdatingDomainBlock(isBlocked: Bool) -> Self {
            switch self {
            case .isMe:
                return self
            case .isNotMe(let info):
                guard info?.iAmBlockingTheirDomain != isBlocked else { return self }
                guard let updatedRelationship = info?._legacyEntity.byUpdatingDomainBlock(isBlocked: isBlocked) else { return self }
                return .isNotMe(RelationshipInfo.init(updatedRelationship, fetchedAt: info?.fetchedAt)) // we keep the old fetchedAt date because this is not a full refresh of the account and should not delay an update being triggered in the future
            }
        }
        
        @MainActor
        var debugString: String {
            switch self {
            case .isMe:
                "isMe-\(AuthenticationServiceProvider.shared.currentActiveUser.value!.userID)"
            case .isNotMe(let info):
                if let info {
                    "notMe(\(info._legacyEntity.id))"
                } else {
                    "notMe(NO INFO)"
                }
            }
        }
    }
    
    struct RelationshipInfo: Codable {
        let id: Mastodon.Entity.Account.ID  // id of the account
        let fetchedAt: Date?
        let iFollowThem: Bool
        let iHideTheirBoosts: Bool
        let theyFollowMe: Bool?
        let iHaveRequestedToFollowThem: Bool
        let iAmMutingThem: Bool
        let iAmBlockingTheirDomain: Bool
        let iAmBlockingThem: Bool
        let iFeatureThem: Bool
        let myOwnComment: String?
        let _legacyEntity: Mastodon.Entity.Relationship
        
        init(_ entity: Mastodon.Entity.Relationship, fetchedAt: Date?) {
            id = entity.id
            self.fetchedAt = fetchedAt
            iFollowThem = entity.following
            iHideTheirBoosts = !entity.showingReblogs
            theyFollowMe = entity.followedBy
            iHaveRequestedToFollowThem = entity.requested
            iAmMutingThem = entity.muting
            iAmBlockingThem = entity.blocking
            iAmBlockingTheirDomain = entity.domainBlocking
            iFeatureThem = entity.endorsed
            myOwnComment = entity.note
            _legacyEntity = entity
        }
        
        var canFollow: Bool {
            return !iFollowThem && !iHaveRequestedToFollowThem
        }
        
        var canUnfollow: Bool {
            return iFollowThem || iHaveRequestedToFollowThem
        }
    }
}

extension MastodonAccount: UserIdentifier {
    public var domain: String {
        _legacyEntity.domain ?? ""
    }
    
    public var userID: MastodonSDK.Mastodon.Entity.Account.ID {
        id
    }
}


func escapeHtml(_ html: String) -> String {
    var escaped = html
    escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
    escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
    escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
    escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
    escaped = escaped.replacingOccurrences(of: "'", with: "&#39;")
    return escaped
}
