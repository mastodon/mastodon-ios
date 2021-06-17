//
//  Date.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-1.
//

import Foundation
import DateToolsSwift

extension Date {
    
    var slowedTimeAgoSinceNow: String {
        return self.slowedTimeAgo(since: Date())
        
    }
    
    func slowedTimeAgo(since date: Date) -> String {
        let earlierDate = date < self ? date : self
        let latest = earlierDate == date ? self : date
        
        if earlierDate.timeIntervalSince(latest) >= -60 {
            return L10n.Common.Controls.Timeline.Timestamp.now
        } else {
            let interval = latest.shortTimeAgo(since: earlierDate)              // 1s
            return L10n.Common.Controls.Timeline.Timestamp.timeAgo(interval)    // 1s ago
        }
    }
    
}
