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
        formatter.unitsStyle = .full
        return formatter
    }()
    
    var localizedSlowedTimeAgoSinceNow: String {
        return self.localizedTimeAgo(since: Date(), isSlowed: true, isAbbreviated: true)
    }
    
    var localizedTimeAgoSinceNow: String {
        return self.localizedTimeAgo(since: Date(), isSlowed: false, isAbbreviated: false)
    }
    
    func localizedTimeAgo(since date: Date, isSlowed: Bool, isAbbreviated: Bool) -> String {
        let earlierDate = date < self ? date : self
        let latestDate = earlierDate == date ? self : date
        
        if isSlowed, earlierDate.timeIntervalSince(latestDate) >= -60 {
            return L10n.Common.Controls.Timeline.Timestamp.now
        } else {
            if isAbbreviated {
                return latestDate.shortTimeAgo(since: earlierDate)
            } else {
                return Date.relativeTimestampFormatter.localizedString(for: earlierDate, relativeTo: latestDate)
            }
        }
    }
    
}

extension Date {
    
    func localizedTimeLeft() -> String {
        let date = Date()
        let earlierDate = date < self ? date : self
        let latestDate = earlierDate == date ? self : date
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: earlierDate, to: latestDate)
        
        if components.year! > 0 {
            return L10n.Date.Year.left(components.second!)
        } else if components.month! > 0 {
            return L10n.Date.Month.left(components.month!)
        } else if components.day! > 0 {
            return L10n.Date.Day.left(components.day!)
        } else if components.hour! > 0 {
            return L10n.Date.Hour.left(components.hour!)
        } else if components.minute! > 0 {
            return L10n.Date.Minute.left(components.minute!)
        } else if components.second! > 0 {
            return L10n.Date.Year.left(components.second!)
        } else {
            return ""
        }
    }
    
}
