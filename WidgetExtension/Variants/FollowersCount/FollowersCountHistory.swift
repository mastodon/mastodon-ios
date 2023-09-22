// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

struct FollowersCountHistoryDay: Codable {
    let dstring: String
    let day: Int
    let count: Int
    
    func copy(count: Int) -> Self {
        FollowersCountHistoryDay(dstring: dstring, day: day, count: count)
    }
}

class FollowersCountHistory {
    
    static let shared = FollowersCountHistory()
    
    private let userDefaults = UserDefaults.standard
    private let calendar = Calendar.current
    private let followersCountCacheDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
    
    private func elapsedFollowersCountDateStrings() -> [String] {
        (-7...0).map { elapsedDay in
            let date = calendar.date(byAdding: .day, value: elapsedDay, to: .now)!
            return followersCountCacheDateFormatter.string(from: date)
        }
    }
    
    private func userDefaultsKey(for account: FollowersEntryAccountable) -> String {
        if account.acct.contains("@") {
            return account.acct
        }
        return "\(account.acct)@\(account.domain)"
    }
    
    private func emptyHistoricDataForToday(for account: FollowersEntryAccountable) -> [FollowersCountHistoryDay] {
        elapsedFollowersCountDateStrings().enumerated().map { FollowersCountHistoryDay(dstring: $0.element, day: $0.offset, count: account.followersCount) }
    }
    
    private func followersHistorySorted(for account: FollowersEntryAccountable) -> [FollowersCountHistoryDay] {
        guard
            let jsonData = userDefaults.string(forKey: userDefaultsKey(for: account))?.data(using: .utf8),
            let jsonObject = try? JSONDecoder().decode([FollowersCountHistoryDay].self, from: jsonData)
        else {
            return emptyHistoricDataForToday(for: account)
        }
        return jsonObject
    }
    
    func updateFollowersTodayCount(account: FollowersEntryAccountable, count: Int) {
        let relevantDays = elapsedFollowersCountDateStrings()
        let existingHistory = followersHistorySorted(for: account)
        var newHistory = existingHistory
        
        /// first we're going to update the existing day and remove legacy days (older than 7)
        existingHistory.forEach { existingDay in
            if !relevantDays.contains(where: { $0 == existingDay.dstring }) {
                /// remove legacy data/
                newHistory.removeAll(where: { $0.dstring == existingDay.dstring })
            }
        }

        relevantDays.enumerated().forEach { index, day in
            if !newHistory.contains(where: { $0.dstring == day }) {
                newHistory.insert(
                    FollowersCountHistoryDay(dstring: day, day: index, count: account.followersCount),
                    at: index
                )
            }
        }

        /// then we're going to update the history dataset with new value, if this is the first encounter
        if let last = newHistory.popLast()?.copy(count: count) {
            newHistory.append(last)
        }

        if let jsonData = try? JSONEncoder().encode(newHistory), let jsonString = String(data: jsonData, encoding: .utf8) {
            userDefaults.set(jsonString, forKey: userDefaultsKey(for: account))
        }
    }
    
    func chartValues(for account: FollowersEntryAccountable) -> [Double] {
        followersHistorySorted(for: account).map { Double($0.count) }
    }
    
    func increaseCountString(for account: FollowersEntryAccountable) -> String? {
        let history = followersHistorySorted(for: account)
        let relevantDays = elapsedFollowersCountDateStrings()
        let today = relevantDays.last!

        let followersToday = history.first(where: { $0.dstring == today })?.count ?? account.followersCount
        let followersYesterday = history[safe: history.count-2]?.count ?? account.followersCount
        
        let followersChange = followersToday - followersYesterday
        
        switch followersChange {
        case ..<0:
            return "\(followersChange)"
        case 0:
            return nil
        default:
            return "+\(followersChange)"
        }
    }
}
