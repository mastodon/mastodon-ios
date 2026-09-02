// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Combine
import CoreDataStack // Needed until migration of push notification subscriptions has had time to occur

public enum ContentWarning {
    case warnNothing
    case warnMediaOnly
    case warnWholePost(message: String)
    
    public init(status: MastodonStatus) {
        let entity = status.entity.reblog ?? status.entity
        let hasSpoilerText = entity.spoilerText != nil && !entity.spoilerText!.isEmpty
        let isMarkedSensitive = entity.sensitive ?? false
        let fallbackWarningText = ""
        switch (hasSpoilerText, isMarkedSensitive) {
        case (true, true):
            self = .warnWholePost(message: entity.spoilerText ?? fallbackWarningText)
        case (true, false):
            self = .warnWholePost(message: entity.spoilerText ?? fallbackWarningText)
        case (false, true):
            self = .warnMediaOnly
        case (false, false):
            self = .warnNothing
        }
    }
    
    public init(status: Mastodon.Entity.Status) {
        let statusWithContent = status.reblog ?? status
        let hasSpoilerText = statusWithContent.spoilerText != nil && !statusWithContent.spoilerText!.isEmpty
        let isMarkedSensitive = statusWithContent.sensitive ?? false
        let fallbackWarningText = ""
        switch (hasSpoilerText, isMarkedSensitive) {
        case (true, true):
            self = .warnWholePost(message: statusWithContent.spoilerText ?? fallbackWarningText)
        case (true, false):
            self = .warnWholePost(message: statusWithContent.spoilerText ?? fallbackWarningText)
        case (false, true):
            self = .warnMediaOnly
        case (false, false):
            self = .warnNothing
        }
    }
    
    public init(statusEdit: Mastodon.Entity.StatusEdit) {
        let entity = statusEdit
        let hasSpoilerText = entity.spoilerText != nil && !entity.spoilerText!.isEmpty
        let isMarkedSensitive = entity.sensitive
        let fallbackWarningText = ""
        switch (hasSpoilerText, isMarkedSensitive) {
        case (true, true):
            self = .warnWholePost(message: entity.spoilerText ?? fallbackWarningText)
        case (true, false):
            self = .warnWholePost(message: entity.spoilerText ?? fallbackWarningText)
        case (false, true):
            self = .warnMediaOnly
        case (false, false):
            self = .warnNothing
        }
    }
    
}

//@available(*, deprecated, message: "migrate to Mastodon.Entity.Status")
public final class MastodonStatus: ObservableObject {
    public typealias ID = Mastodon.Entity.Status.ID
    
    /// `originalStatus` is used to restore a previously re-blogged state when a status
    /// has been originally reblogged by another account
    @Published public var originalStatus: MastodonStatus?
    
    @Published public var entity: Mastodon.Entity.Status
    @Published public var reblog: MastodonStatus?
    
    @Published public var showDespiteContentWarning: Bool = false
    @Published public var showDespiteFilter: Bool = false
    
    @Published public var poll: MastodonPoll?
    
    public init(entity: Mastodon.Entity.Status, showDespiteContentWarning: Bool) {
        self.entity = entity
        self.showDespiteContentWarning = showDespiteContentWarning
        
        if let poll = entity.poll {
            self.poll = .init(poll: poll, status: self)
        }
        
        if let reblog = entity.reblog {
            self.reblog = MastodonStatus.fromEntity(reblog)
        } else {
            self.reblog = nil
        }
    }
    
    public var id: ID {
        entity.id
    }
}

extension MastodonStatus {
    public static func fromEntity(_ entity: Mastodon.Entity.Status) -> MastodonStatus {
        return MastodonStatus(entity: entity, showDespiteContentWarning: false)
    }
    
    public func inheritSensitivityToggled(from status: MastodonStatus?) -> MastodonStatus {
        self.showDespiteContentWarning = status?.showDespiteContentWarning ?? false
        self.reblog?.showDespiteContentWarning = status?.reblog?.showDespiteContentWarning ?? false
        return self
    }
    
    public func withOriginal(status: MastodonStatus?) -> MastodonStatus {
        originalStatus = status
        return self
    }
    
    public func withPoll(_ poll: MastodonPoll?) -> MastodonStatus {
        self.poll = poll
        return self
    }
}

extension MastodonStatus: Hashable {
    public static func == (lhs: MastodonStatus, rhs: MastodonStatus) -> Bool {
        lhs.entity == rhs.entity &&
        lhs.poll == rhs.poll &&
        lhs.entity.poll == rhs.entity.poll &&
        lhs.reblog?.entity == rhs.reblog?.entity &&
        lhs.reblog?.poll == rhs.reblog?.poll &&
        lhs.reblog?.entity.poll == rhs.reblog?.entity.poll &&
        lhs.showDespiteContentWarning == rhs.showDespiteContentWarning &&
        lhs.reblog?.showDespiteContentWarning == rhs.reblog?.showDespiteContentWarning &&
        lhs.entity.reblogged == rhs.entity.reblogged &&
        lhs.entity.repliesCount == rhs.entity.repliesCount &&
        lhs.entity.favourited == rhs.entity.favourited &&
        lhs.entity.reblogsCount == rhs.entity.reblogsCount &&
        lhs.entity.favouritesCount == rhs.entity.favouritesCount
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(entity)
        hasher.combine(poll)
        hasher.combine(reblog?.entity)
        hasher.combine(reblog?.poll)
        hasher.combine(showDespiteContentWarning)
        hasher.combine(reblog?.showDespiteContentWarning)
    }
}

public extension Mastodon.Entity.Status {
    var asMastodonStatus: MastodonStatus {
        .fromEntity(self)
    }
}

public extension MastodonStatus {
    enum UpdateIntent {
        case bookmark(Bool)
        case reblog(Bool)
        case favorite(Bool)
        case toggleSensitive(Bool)
        case delete
        case edit
        case pollVote
    }
}

