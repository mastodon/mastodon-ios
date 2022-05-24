//
//  Date.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-1.
//

import Foundation
import MastodonAsset
import MastodonLocalization

extension Date {
    
    static let calendar = Calendar(identifier: .gregorian)
    
    public static let relativeTimestampFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .full
        return formatter
    }()
    
    public static let abbreviatedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium       // e.g. Nov 23, 1937
        formatter.timeStyle = .none         // none
        return formatter
    }()
        
    public var localizedSlowedTimeAgoSinceNow: String {
        return self.localizedTimeAgo(since: Date(), isSlowed: true, isAbbreviated: false)
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
                if earlierDate.timeIntervalSince(latestDate) < -(7 * 24 * 60 * 60) {
                    let currentYear = Date.calendar.dateComponents([.year], from: Date())
                    let earlierDateYear = Date.calendar.dateComponents([.year], from: earlierDate)
                    if #available(iOS 15.0, *) {
                        if currentYear.year! > earlierDateYear.year! {
                            return earlierDate.formatted(.dateTime.year().month(.abbreviated).day())
                        } else {
                            return earlierDate.formatted(.dateTime.month(.abbreviated).day())
                        }
                    } else {
                        return Date.abbreviatedDateFormatter.string(from: earlierDate)
                    }
                } else {
                    return Date.relativeTimestampFormatter.localizedString(for: earlierDate, relativeTo: latestDate)
                }
            }
        }
    }
    
}

extension Date {
    
    public func localizedShortTimeAgo(since date: Date) -> String {
        let earlierDate = date < self ? date : self
        let latestDate = earlierDate == date ? self : date
        
        let components = Date.calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: earlierDate, to: latestDate)
        
        if components.year! > 0 {
            return L10n.Date.Year.Ago.abbr(components.year!)
        } else if components.month! > 0 {
            return L10n.Date.Month.Ago.abbr(components.month!)
        } else if components.day! > 0 {
            return L10n.Date.Day.Ago.abbr(components.day!)
        } else if components.hour! > 0 {
            return L10n.Date.Hour.Ago.abbr(components.hour!)
        } else if components.minute! > 0 {
            return L10n.Date.Minute.Ago.abbr(components.minute!)
        } else if components.second! > 0 {
            return L10n.Date.Year.Ago.abbr(components.second!)
        } else {
            return ""
        }
    }
    
    public func localizedTimeLeft() -> String {
        let date = Date()
        let earlierDate = date < self ? date : self
        let latestDate = earlierDate == date ? self : date
        
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day, .hour, .minute, .second], from: earlierDate, to: latestDate)
        
        if components.year! > 0 {
            return L10n.Date.Year.left(components.year!)
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
