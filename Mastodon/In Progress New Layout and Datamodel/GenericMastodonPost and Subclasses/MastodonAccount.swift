// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonSDK

struct MastodonAccount: Identifiable, Codable {
    let id: Mastodon.Entity.Account.ID
    let metadata: MetaData
    let displayInfo: DisplayInfo
    let metrics: Metrics
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
    }
}

extension MastodonAccount {
    struct DisplayInfo: Codable {
        let handle: String
        let displayName: String
        let emojis: [Mastodon.Entity.Emoji]
        private let avatarImage: ImageUrl
        private let headerImage: ImageUrl?

        var avatarUrl: URL {
            return avatarImage.preferredUrl
        }

        var headerUrl: URL? {
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
        _ entity: Mastodon.Entity.Account
    ) -> Self
}

extension MastodonAccount: FromAccountEntityDerivable {
    static func fromEntity(
        _ entity: Mastodon.Entity.Account
    ) -> Self {
        return MastodonAccount(
            id: entity.id,
            metadata: MetaData.fromEntity(entity),
            displayInfo: DisplayInfo.fromEntity(
                entity),
            metrics: Metrics.fromEntity(entity),
            _legacyEntity: entity
        )
    }
}

extension MastodonAccount.MetaData: FromAccountEntityDerivable {
    static func fromEntity(_ entity: Mastodon.Entity.Account) -> MastodonAccount.MetaData {
        return MastodonAccount.MetaData(profileUrl: URL(string: entity.url), createdAt: entity.createdAt, manuallyApprovesNewFollows: entity.locked, verifiedLink: entity.verifiedLink?.value)
    }
}

extension MastodonAccount.DisplayInfo: FromAccountEntityDerivable {
    static func fromEntity(
        _ entity: Mastodon.Entity.Account
    ) -> Self {
        // TODO: GET THE ACTUAL USER DOMAIN! or just get the image and keep it somewhere
        let currentUserDomain = "mastodon.social"
        let avatarImage = ImageUrl(
            potentiallyAnimated: entity.avatar,
            definitelyStatic: entity.avatarStatic,
            fallback: fallbackAvatarURL(
                fromCurrentUserDomain: currentUserDomain))!
        let headerImage = ImageUrl(
            potentiallyAnimated: entity.avatar,
            definitelyStatic: entity.avatarStatic,
            fallback: fallbackAvatarURL(
                fromCurrentUserDomain: currentUserDomain))
        return Self(
            handle: entity.acct, displayName: entity.displayNameWithFallback,
            emojis: entity.emojis, avatarImage: avatarImage,
            headerImage: headerImage)
    }
}

extension MastodonAccount.Metrics: FromAccountEntityDerivable {
    static func fromEntity(_ entity: Mastodon.Entity.Account) -> Self {
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
    }
    
    struct RelationshipInfo: Codable {
        let id: Mastodon.Entity.Account.ID  // id of the account
        let fetchedAt: Date?
        let iFollowThem: Bool
        let iHaveRequestedToFollowThem: Bool
        let iAmMutingThem: Bool
        let iAmBlockingThem: Bool
        let _legacyEntity: Mastodon.Entity.Relationship
        
        init(_ entity: Mastodon.Entity.Relationship, fetchedAt: Date?) {
            id = entity.id
            self.fetchedAt = fetchedAt
            iFollowThem = entity.following
            iHaveRequestedToFollowThem = entity.requested
            iAmMutingThem = entity.muting
            iAmBlockingThem = entity.blocking
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
