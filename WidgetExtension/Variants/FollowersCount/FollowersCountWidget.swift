// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI
import Intents
import MastodonSDK
import MastodonLocalization

struct FollowersCountWidgetProvider: IntentTimelineProvider {
    private let followersHistory = FollowersCountHistory.shared
    
    func placeholder(in context: Context) -> FollowersCountEntry {
        .placeholder
    }

    func getSnapshot(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (FollowersCountEntry) -> ()) {
        loadCurrentEntry(for: configuration, in: context, completion: completion)
    }

    func getTimeline(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (Timeline<FollowersCountEntry>) -> ()) {
        loadCurrentEntry(for: configuration, in: context) { entry in
            completion(Timeline(entries: [entry], policy: .after(.now)))
        }
    }
}

struct FollowersCountEntry: TimelineEntry {
    let date: Date
    let account: FollowersEntryAccountable?
    let configuration: FollowersCountIntent
    
    static var placeholder: Self {
        FollowersCountEntry(
            date: .now,
            account: FollowersEntryAccount(
                followersCount: 99_900,
                displayNameWithFallback: "Mastodon",
                acct: "mastodon",
                avatarImage: UIImage(named: "missingAvatar")!,
                domain: "mastodon"
            ),
            configuration: FollowersCountIntent()
        )
    }
    
    static var unconfigured: Self {
        FollowersCountEntry(
            date: .now,
            account: nil,
            configuration: FollowersCountIntent()
        )
    }
}

struct FollowersCountWidget: Widget {
    private var availableFamilies: [WidgetFamily] {
        if #available(iOS 16, *) {
            return [.systemSmall, .accessoryRectangular, .accessoryCircular]
        }
        return [.systemSmall]
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "Followers", intent: FollowersCountIntent.self, provider: FollowersCountWidgetProvider()) { entry in
            FollowersCountWidgetView(entry: entry)
        }
        .configurationDisplayName(L10n.Widget.FollowersCount.configurationDisplayName)
        .description(L10n.Widget.FollowersCount.configurationDescription)
        .supportedFamilies(availableFamilies)
    }
}

private extension FollowersCountWidgetProvider {
    func loadCurrentEntry(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (FollowersCountEntry) -> Void) {
        Task {
            guard
                let authBox = WidgetExtension.appContext
                    .authenticationService
                    .mastodonAuthenticationBoxes
                    .first
            else {
                guard !context.isPreview else {
                    return completion(.placeholder)
                }
                return completion(.unconfigured)
            }
            
            guard
                let desiredAccount = configuration.account ?? authBox.authentication.user(
                    in: WidgetExtension.appContext.managedObjectContext
                )?.acctWithDomain
            else {
                return completion(.unconfigured)
            }
            
            guard
                let resultingAccount = try await WidgetExtension.appContext
                    .apiService
                    .search(query: .init(q: desiredAccount, type: .accounts), authenticationBox: authBox)
                    .value
                    .accounts
                    .first(where: { $0.acctWithDomainIfMissing(authBox.domain) == desiredAccount })
            else {
                return completion(.unconfigured)
            }
            
            let imageData = try await URLSession.shared.data(from: resultingAccount.avatarImageURLWithFallback(domain: authBox.domain)).0
                        
            let entry = FollowersCountEntry(
                date: Date(),
                account: FollowersEntryAccount.from(
                    mastodonAccount: resultingAccount,
                    domain: authBox.domain,
                    avatarImage: UIImage(data: imageData) ?? UIImage(named: "missingAvatar")!
                ),
                configuration: configuration
            )
            
            followersHistory.updateFollowersTodayCount(
                account: entry.account!,
                count: resultingAccount.followersCount
            )
            
            completion(entry)
        }
    }
}

protocol FollowersEntryAccountable {
    var followersCount: Int { get }
    var displayNameWithFallback: String { get }
    var acct: String { get }
    var avatarImage: UIImage { get }
    var domain: String { get }
}

struct FollowersEntryAccount: FollowersEntryAccountable {
    let followersCount: Int
    let displayNameWithFallback: String
    let acct: String
    let avatarImage: UIImage
    let domain: String
    
    static func from(mastodonAccount: Mastodon.Entity.Account, domain: String, avatarImage: UIImage) -> Self {
        FollowersEntryAccount(
            followersCount: mastodonAccount.followersCount,
            displayNameWithFallback: mastodonAccount.displayNameWithFallback,
            acct: mastodonAccount.acct,
            avatarImage: avatarImage,
            domain: domain
        )
    }
}
