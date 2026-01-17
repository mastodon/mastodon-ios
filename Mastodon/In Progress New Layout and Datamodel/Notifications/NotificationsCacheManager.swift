// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import MastodonCore

protocol NotificationsResultType: CacheableFeed {
    var hasContents: Bool { get }
}
extension Mastodon.Entity.GroupedNotificationsResults: NotificationsResultType {
    var hasContents: Bool {
        return notificationGroups.isNotEmpty
    }
}
extension Array<Mastodon.Entity.Notification>: NotificationsResultType {
    var hasContents: Bool {
        return isNotEmpty
    }
}

extension Array<Mastodon.Entity.Notification>: CacheableFeed {
    public var hasResults: Bool {
        return !isEmpty
    }
}

extension Mastodon.Entity.GroupedNotificationsResults: CacheableFeed {
    public var hasResults: Bool {
        hasContents
    }
}

enum Fetchable<T> {
    case initial
    case fetching
    case known(T?)
    
    var value: T? {
        switch self {
        case .initial, .fetching:
            return nil
        case .known(let value):
            return value
        }
    }
}

fileprivate func merge<T: Overlappable>(newer: [T], older: [T], assumeOverlap: Bool = true) -> ([T], [T]?) {
    // There can be multiple matches between the older and newer feeds, with no guarantee of order. The newer version of a duplicate is always the one that should be used.
    // Note that the check here is not fully sufficient to test for a gap between freshly fetched notifications and cached notifications (this check could miss a gap that was skipped over by a group that got promoted far enough up the list), which is why for now we fetch with a minID to avoid gaps and always assume there is an overlap.
    
    var dedupedNewer = [T]()
    var dedupedOlder = [T]()
    var alreadyAdded = Set<T.ID>()
    var hasOverlap = false

    for element in newer {
        guard !alreadyAdded.contains(element.id) else { continue }
        dedupedNewer.append(element)
        alreadyAdded.insert(element.id)
    }

    for element in older {
        guard !alreadyAdded.contains(element.id) else { hasOverlap = true; continue }
        dedupedOlder.append(element)
        alreadyAdded.insert(element.id)
    }
    
    if hasOverlap || assumeOverlap {
        return (dedupedNewer + dedupedOlder, nil)
    } else {
        return (dedupedNewer, dedupedOlder)
    }
}

protocol Overlappable: Identifiable {
    func overlaps(withOlder olderItem: Self) -> Bool
}

extension Mastodon.Entity.Notification: Overlappable {
    func overlaps(withOlder olderItem: Mastodon.Entity.Notification) -> Bool {
        return self.id == olderItem.id
    }
}

extension Mastodon.Entity.NotificationGroup: Overlappable {
    func overlaps(withOlder olderItem: Mastodon.Entity.NotificationGroup) -> Bool {
        return self.id == olderItem.id
    }
}

