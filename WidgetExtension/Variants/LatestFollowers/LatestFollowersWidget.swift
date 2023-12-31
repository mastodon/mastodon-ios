// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI
import Intents
import MastodonSDK
import MastodonLocalization
import MastodonCore

struct LatestFollowersWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> LatestFollowersEntry {
        .placeholder
    }

    func getSnapshot(for configuration: LatestFollowersIntent, in context: Context, completion: @escaping (LatestFollowersEntry) -> ()) {
        loadCurrentEntry(for: configuration, in: context, completion: completion)
    }

    func getTimeline(for configuration: LatestFollowersIntent, in context: Context, completion: @escaping (Timeline<LatestFollowersEntry>) -> ()) {
        loadCurrentEntry(for: configuration, in: context) { entry in
            completion(Timeline(entries: [entry], policy: .after(.now)))
        }
    }
}

struct LatestFollowersEntry: TimelineEntry {
    let date: Date
    let accounts: [LatestFollowersEntryAccountable]?
    let configuration: LatestFollowersIntent
    
    static var placeholder: Self {
        LatestFollowersEntry(
            date: .now,
            accounts: [
                LatestFollowersEntryAccount(
                    note: "Just another Mastodon user",
                    displayNameWithFallback: "Mastodon",
                    acct: "mastodon",
                    avatarImage: UIImage(named: "missingAvatar")!,
                    domain: "mastodon"
                ),
                LatestFollowersEntryAccount(
                    note: "Yet another Mastodon user",
                    displayNameWithFallback: "Mastodon",
                    acct: "mastodon",
                    avatarImage: UIImage(named: "missingAvatar")!,
                    domain: "mastodon"
                )
            ],
            configuration: LatestFollowersIntent()
        )
    }
    
    static var unconfigured: Self {
        LatestFollowersEntry(
            date: .now,
            accounts: nil,
            configuration: LatestFollowersIntent()
        )
    }
}

struct LatestFollowersWidget: Widget {
    private var availableFamilies: [WidgetFamily] {
        return [.systemSmall, .systemMedium]
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "Latest followers", intent: LatestFollowersIntent.self, provider: LatestFollowersWidgetProvider()) { entry in
            LatestFollowersWidgetView(entry: entry)
        }
        .configurationDisplayName(L10n.Widget.LatestFollowers.configurationDisplayName)
        .description(L10n.Widget.LatestFollowers.configurationDescription)
        .supportedFamilies(availableFamilies)
    }
}

private extension LatestFollowersWidgetProvider {
    func loadCurrentEntry(for configuration: LatestFollowersIntent, in context: Context, completion: @escaping (LatestFollowersEntry) -> Void) {
        Task { @MainActor in

            AuthenticationServiceProvider.shared.restore()

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

            var accounts = [LatestFollowersEntryAccountable]()

            let followers = try await WidgetExtension.appContext
                .apiService
                .followers(userID: authBox.userID, maxID: nil, authenticationBox: authBox)
                .value
                .prefix(2) // X most recent followers
            
            for follower in followers {
                let imageData = try await URLSession.shared.data(from: follower.avatarImageURLWithFallback(domain: authBox.domain)).0

                accounts.append(
                    LatestFollowersEntryAccount(
                        note: follower.note,
                        displayNameWithFallback: follower.displayNameWithFallback,
                        acct: follower.acct,
                        avatarImage: UIImage(data: imageData) ?? UIImage(named: "missingAvatar")!,
                        domain: authBox.domain
                    )
                )
            }
            
             let entry = LatestFollowersEntry(
                 date: Date(),
                 accounts: accounts,
                 configuration: configuration
             )

             completion(entry)
        }
    }
}

protocol LatestFollowersEntryAccountable {
    var note: String { get }
    var displayNameWithFallback: String { get }
    var acct: String { get }
    var avatarImage: UIImage { get }
    var domain: String { get }
}

struct LatestFollowersEntryAccount: LatestFollowersEntryAccountable {
    let note: String
    let displayNameWithFallback: String
    let acct: String
    let avatarImage: UIImage
    let domain: String
    
    static func from(mastodonAccount: Mastodon.Entity.Account, domain: String, avatarImage: UIImage) -> Self {
        LatestFollowersEntryAccount(
            note: mastodonAccount.header,
            displayNameWithFallback: mastodonAccount.displayNameWithFallback,
            acct: mastodonAccount.acct,
            avatarImage: avatarImage,
            domain: domain
        )
    }
}
