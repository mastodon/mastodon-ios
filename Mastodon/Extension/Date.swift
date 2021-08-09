//
//  Date.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-1.
//

import Foundation
import DateToolsSwift

extension Date {
    
    static let relativeTimestampFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    var localizedSlowedTimeAgoSinceNow: String {
        return self.localizedSlowedTimeAgo(since: Date())
        
    }
    
    func localizedSlowedTimeAgo(since date: Date) -> String {
        let earlierDate = date < self ? date : self
        let latestDate = earlierDate == date ? self : date
        
        if earlierDate.timeIntervalSince(latestDate) >= -60 {
            return L10n.Common.Controls.Timeline.Timestamp.now
        } else {
            return Date.relativeTimestampFormatter.localizedString(for: earlierDate, relativeTo: latestDate)
        }
    }
    
    func timeLeft() -> String {
        return ""
    }
    
}
