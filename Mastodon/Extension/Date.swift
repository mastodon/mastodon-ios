//
//  Date.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-12.
//

import Foundation
import MastodonAsset
import MastodonLocalization

extension Date {
    
    public static let relativeTimestampFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .full
        return formatter
    }()
    
    public var localizedSlowedTimeAgoSinceNow: String {
        return self.localizedTimeAgo(since: Date(), isSlowed: true, isAbbreviated: true)
    }
    
    public var localizedTimeAgoSinceNow: String {
        return self.localizedTimeAgo(since: Date(), isSlowed: false, isAbbreviated: false)
    }
    
    public func localizedTimeAgo(since date: Date, isSlowed: Bool, isAbbreviated: Bool) -> String {
        let earlierDate = date < self ? date : self
        let latestDate = earlierDate == date ? self : date
        
        if isSlowed, earlierDate.timeIntervalSince(latestDate) >= -60 {
            return L10n.Common.Controls.Timeline.Timestamp.now
        } else {
            if isAbbreviated {
                return latestDate.localizedShortTimeAgo(since: earlierDate)
            } else {
                return Date.relativeTimestampFormatter.localizedString(for: earlierDate, relativeTo: latestDate)
            }
        }
    }
    
}
