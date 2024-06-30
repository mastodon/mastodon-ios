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
        formatter.locale = Locale.autoupdatingCurrent
        formatter.dateTimeStyle = .numeric
        formatter.unitsStyle = .short
        return formatter
    }()

    public static let abbreviatedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium       // e.g. Nov 23, 1937
        formatter.timeStyle = .none         // none
        return formatter
    }()

    public var abbreviatedDate: String {
        return Date.abbreviatedDateFormatter.string(from: self)
    }

    public var localizedAbbreviatedSlowedTimeAgoSinceNow: String {
        return Date.relativeTimestampFormatter.localizedString(for: self, relativeTo: Date())
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
