// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import Combine
import CoreDataStack

public final class MastodonStatus: ObservableObject {
    public typealias ID = Mastodon.Entity.Status.ID
    
    @Published public var entity: Mastodon.Entity.Status
    @Published public var reblog: MastodonStatus?
    
    @Published public var isSensitiveToggled: Bool = false
    
    init(entity: Mastodon.Entity.Status, isSensitiveToggled: Bool) {
        self.entity = entity
        self.isSensitiveToggled = isSensitiveToggled
        
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
        return MastodonStatus(entity: entity, isSensitiveToggled: false)
    }
}

extension MastodonStatus: Hashable {
    public static func == (lhs: MastodonStatus, rhs: MastodonStatus) -> Bool {
        lhs.entity == rhs.entity &&
        lhs.reblog?.entity == rhs.reblog?.entity
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(entity)
        hasher.combine(reblog?.entity)
    }
}

public extension Mastodon.Entity.Status {
    var mastodonVisibility: MastodonVisibility? {
        guard let visibility = visibility?.rawValue else { return nil }
        return MastodonVisibility(rawValue: visibility)
    }
}

