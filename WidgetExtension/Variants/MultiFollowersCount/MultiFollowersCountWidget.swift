// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI
import Intents
import MastodonSDK

struct MultiFollowersCountWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> MultiFollowersCountEntry {
        .placeholder
    }

    func getSnapshot(for configuration: MultiFollowersCountSmallIntent, in context: Context, completion: @escaping (MultiFollowersCountEntry) -> ()) {
        guard !context.isPreview else {
            return completion(.placeholder)
        }
        loadCurrentEntry(for: configuration, in: context, completion: completion)
    }

    func getTimeline(for configuration: MultiFollowersCountSmallIntent, in context: Context, completion: @escaping (Timeline<MultiFollowersCountEntry>) -> ()) {
        loadCurrentEntry(for: configuration, in: context) { entry in
            completion(Timeline(entries: [entry], policy: .after(.now)))
        }
    }
}

struct MultiFollowersCountEntry: TimelineEntry {
    let date: Date
    let accounts: [FollowersEntryAccountable]?
    let configuration: MultiFollowersCountSmallIntent
    
    static var placeholder: Self {
        MultiFollowersCountEntry(
            date: .now,
            accounts: [
                FollowersEntryAccount(
                    followersCount: 99_900,
                    displayNameWithFallback: "Mastodon",
                    acct: "mastodon",
                    avatarImage: UIImage(named: "missingAvatar")!,
                    domain: "mastodon"
                )
            ],
            configuration: MultiFollowersCountSmallIntent()
        )
    }
    
    static var unconfigured: Self {
        MultiFollowersCountEntry(
            date: .now,
            accounts: [],
            configuration: MultiFollowersCountSmallIntent()
        )
    }
}

struct MultiFollowersCountWidget: Widget {
    private var availableFamilies: [WidgetFamily] {
        return [.systemSmall]
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "Multiple followers", intent: MultiFollowersCountSmallIntent.self, provider: MultiFollowersCountWidgetProvider()) { entry in
            MultiFollowersCountWidgetView(entry: entry)
        }
        .configurationDisplayName("Multiple followers")
        .description("Show number of followers for multiple accounts.")
        .supportedFamilies(availableFamilies)
    }
}

private extension MultiFollowersCountWidgetProvider {
    func loadCurrentEntry(for configuration: MultiFollowersCountSmallIntent, in context: Context, completion: @escaping (MultiFollowersCountEntry) -> Void) {
        Task {
            guard
                let authBox = WidgetExtension.appContext
                    .authenticationService
                    .mastodonAuthenticationBoxes
                    .first
            else {
                return completion(.unconfigured)
            }
            
            guard let desiredAccounts: [String] = {
                guard let account = configuration.accounts?.compactMap({ $0 }) else {
                    if let acct = authBox.authenticationRecord.object(in: WidgetExtension.appContext.managedObjectContext)?.user.acct {
                        return [acct]
                    }
                    return nil
                }
                return account
            }() else {
                return completion(.unconfigured)
            }
            
            var accounts = [FollowersEntryAccountable]()
            
            for desiredAccount in desiredAccounts {
                let resultingAccount = try await WidgetExtension.appContext
                    .apiService
                    .search(query: .init(q: desiredAccount, type: .accounts), authenticationBox: authBox)
                    .value
                    .accounts
                    .first!
                
                let imageData = try await URLSession.shared.data(from: resultingAccount.avatarImageURLWithFallback(domain: authBox.domain)).0
                
                accounts.append(FollowersEntryAccount.from(
                    mastodonAccount: resultingAccount,
                    domain: authBox.domain,
                    avatarImage: UIImage(data: imageData) ?? UIImage(named: "missingAvatar")!
                ))
            }
       
            let entry = MultiFollowersCountEntry(
                date: Date(),
                accounts: accounts,
                configuration: configuration
            )

            completion(entry)
        }
    }
}

protocol MultiFollowersEntryAccountable {
    var followersCount: Int { get }
    var displayNameWithFallback: String { get }
    var acct: String { get }
    var avatarImage: UIImage { get }
    var domain: String { get }
}

struct MultiFollowersEntryAccount: MultiFollowersEntryAccountable {
    let followersCount: Int
    let displayNameWithFallback: String
    let acct: String
    let avatarImage: UIImage
    let domain: String
    
    static func from(mastodonAccount: Mastodon.Entity.Account, domain: String, avatarImage: UIImage) -> Self {
        MultiFollowersEntryAccount(
            followersCount: mastodonAccount.followersCount,
            displayNameWithFallback: mastodonAccount.displayNameWithFallback,
            acct: mastodonAccount.acct,
            avatarImage: avatarImage,
            domain: domain
        )
    }
}
