// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI
import Intents
import MastodonSDK
import MastodonLocalization

struct MultiFollowersCountWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> MultiFollowersCountEntry {
        .placeholder
    }

    func getSnapshot(for configuration: MultiFollowersCountIntent, in context: Context, completion: @escaping (MultiFollowersCountEntry) -> ()) {
        loadCurrentEntry(for: configuration, in: context, completion: completion)
    }

    func getTimeline(for configuration: MultiFollowersCountIntent, in context: Context, completion: @escaping (Timeline<MultiFollowersCountEntry>) -> ()) {
        loadCurrentEntry(for: configuration, in: context) { entry in
            completion(Timeline(entries: [entry], policy: .after(.now)))
        }
    }
}

struct MultiFollowersCountEntry: TimelineEntry {
    let date: Date
    let accounts: [MultiFollowersEntryAccountable]?
    let configuration: MultiFollowersCountIntent
    
    static var placeholder: Self {
        MultiFollowersCountEntry(
            date: .now,
            accounts: [
                MultiFollowersEntryAccount(
                    followersCount: 99_900,
                    displayNameWithFallback: "Mastodon",
                    acct: "mastodon",
                    avatarImage: UIImage(named: "missingAvatar")!,
                    domain: "mastodon"
                )
            ],
            configuration: MultiFollowersCountIntent()
        )
    }
    
    static var unconfigured: Self {
        MultiFollowersCountEntry(
            date: .now,
            accounts: nil,
            configuration: MultiFollowersCountIntent()
        )
    }
}

struct MultiFollowersCountWidget: Widget {
    private var availableFamilies: [WidgetFamily] {
        return [.systemSmall, .systemMedium]
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "Multiple followers", intent: MultiFollowersCountIntent.self, provider: MultiFollowersCountWidgetProvider()) { entry in
            MultiFollowersCountWidgetView(entry: entry)
        }
        .configurationDisplayName(L10n.Widget.MultipleFollowers.configurationDisplayName)
        .description(L10n.Widget.MultipleFollowers.configurationDescription)
        .supportedFamilies(availableFamilies)
    }
}

private extension MultiFollowersCountWidgetProvider {
    func loadCurrentEntry(for configuration: MultiFollowersCountIntent, in context: Context, completion: @escaping (MultiFollowersCountEntry) -> Void) {
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
            
            let desiredAccounts: [String]
            
            if let configuredAccounts = configuration.accounts?.compactMap({ $0 }) {
                desiredAccounts = configuredAccounts
            } else if let currentlyLoggedInAccount = authBox.authenticationRecord.object(
                in: WidgetExtension.appContext.managedObjectContext
            )?.user.acct {
                desiredAccounts = [currentlyLoggedInAccount]
            } else {
                return completion(.unconfigured)
            }

            var accounts = [MultiFollowersEntryAccountable]()
            
            for desiredAccount in desiredAccounts {
                guard
                    let resultingAccount = try await WidgetExtension.appContext
                        .apiService
                        .search(query: .init(q: desiredAccount, type: .accounts), authenticationBox: authBox)
                        .value
                        .accounts
                        .first(where: { $0.acct == desiredAccount })
                else {
                    continue
                }
                
                let imageData = try await URLSession.shared.data(from: resultingAccount.avatarImageURLWithFallback(domain: authBox.domain)).0
                
                accounts.append(MultiFollowersEntryAccount.from(
                    mastodonAccount: resultingAccount,
                    domain: authBox.domain,
                    avatarImage: UIImage(data: imageData) ?? UIImage(named: "missingAvatar")!
                ))
            }
            
            if context.isPreview {
                accounts.append(
                    MultiFollowersEntryAccount(
                        followersCount: 1_200,
                        displayNameWithFallback: L10n.Widget.MultipleFollowers.MockUser.displayName,
                        acct: L10n.Widget.MultipleFollowers.MockUser.accountName,
                        avatarImage: UIImage(named: "missingAvatar")!,
                        domain: authBox.domain
                    )
                )
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
