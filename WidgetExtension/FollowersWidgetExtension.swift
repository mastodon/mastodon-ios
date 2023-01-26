// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI
import Intents
import MastodonSDK

struct FollowersProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> FollowersEntry {
        .placeholder
    }

    func getSnapshot(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (FollowersEntry) -> ()) {
        guard !context.isPreview else {
            return completion(.placeholder)
        }
        loadCurrentEntry(for: configuration, in: context, completion: completion)
    }

    func getTimeline(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (Timeline<FollowersEntry>) -> ()) {
        loadCurrentEntry(for: configuration, in: context) { entry in
            completion(Timeline(entries: [entry], policy: .after(.now)))
        }
    }
}

struct FollowersEntry: TimelineEntry {
    let date: Date
    let account: FollowersEntryAccountable?
    let configuration: FollowersCountIntent
    
    static var placeholder: Self {
        FollowersEntry(
            date: .now,
            account: FollowersEntryAccount(
                followersCount: 99_900,
                displayNameWithFallback: "Mastodon",
                acct: "mastodon",
                avatarImage: UIImage(named: "missingAvatar")!
            ),
            configuration: FollowersCountIntent()
        )
    }
    
    static var unconfigured: Self {
        FollowersEntry(
            date: .now,
            account: nil,
            configuration: FollowersCountIntent()
        )
    }
}

struct FollowersWidgetExtension: Widget {
    private var availableFamilies: [WidgetFamily] {
        if #available(iOS 16, *) {
            return [.systemSmall, .accessoryRectangular, .accessoryCircular]
        }
        return [.systemSmall]
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "Followers", intent: FollowersCountIntent.self, provider: FollowersProvider()) { entry in
            FollowCountWidgetView(entry: entry)
        }
        .configurationDisplayName("Followers")
        .description("Show number of followers.")
        .supportedFamilies(availableFamilies)
    }
}

private extension FollowersProvider {
    func loadCurrentEntry(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (FollowersEntry) -> Void) {
        Task {
            guard
                let authBox = WidgetExtension.appContext
                    .authenticationService
                    .mastodonAuthenticationBoxes
                    .first
            else {
                return completion(.unconfigured)
            }
            
            guard let desiredAccount: String = {
                guard let account = configuration.account else {
                    return authBox.authenticationRecord.object(in: WidgetExtension.appContext.managedObjectContext)?.user.acct
                }
                return account
            }() else {
                return completion(.unconfigured)
            }
            
            let resultingAccount = try await WidgetExtension.appContext
                .apiService
                .search(query: .init(q: desiredAccount, type: .accounts), authenticationBox: authBox)
                .value
                .accounts
                .first!
            
            let imageData = try await URLSession.shared.data(from: resultingAccount.avatarImageURLWithFallback(domain: authBox.domain)).0
                        
            let entry = FollowersEntry(
                date: Date(),
                account: FollowersEntryAccount.from(
                    mastodonAccount: resultingAccount,
                    avatarImage: UIImage(data: imageData) ?? UIImage(named: "missingAvatar")!
                ),
                configuration: configuration
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
}

struct FollowersEntryAccount: FollowersEntryAccountable {
    let followersCount: Int
    let displayNameWithFallback: String
    let acct: String
    let avatarImage: UIImage
    
    static func from(mastodonAccount: Mastodon.Entity.Account, avatarImage: UIImage) -> Self {
        FollowersEntryAccount(
            followersCount: mastodonAccount.followersCount,
            displayNameWithFallback: mastodonAccount.displayNameWithFallback,
            acct: mastodonAccount.acct,
            avatarImage: avatarImage
        )
    }
}
