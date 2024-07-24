// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI
import MastodonSDK
import MastodonLocalization
import MastodonCore

struct HashtagWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> HashtagWidgetTimelineEntry {
        .placeholder
    }

    func getSnapshot(for configuration: HashtagIntent, in context: Context, completion: @escaping (HashtagWidgetTimelineEntry) -> Void) {
        loadMostRecentHashtag(for: configuration, in: context, completion: completion)
    }

    func getTimeline(for configuration: HashtagIntent, in context: Context, completion: @escaping (Timeline<HashtagWidgetTimelineEntry>) -> Void) {
        loadMostRecentHashtag(for: configuration, in: context) { entry in
            completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60 * 15))))
        }
    }
}

extension HashtagWidgetProvider {
    func loadMostRecentHashtag(for configuration: HashtagIntent, in context: Context, completion: @escaping (HashtagWidgetTimelineEntry) -> Void ) {

        AuthenticationServiceProvider.shared.restore()

        guard
            let authBox = WidgetExtension.appContext
                .authenticationService
                .mastodonAuthenticationBoxes
                .first
        else {
            if context.isPreview {
                return completion(.placeholder)
            } else {
                return completion(.unconfigured)
            }
        }

        let desiredHashtag: String

        if let hashtag = configuration.hashtag {
            desiredHashtag = hashtag.replacingOccurrences(of: "#", with: "")
        } else {
            return completion(.notFound("hashtag"))
        }

        Task {

            do {
                let mostRecentStatuses = try await WidgetExtension.appContext
                    .apiService
                    .hashtagTimeline(limit: 40, hashtag: desiredHashtag, authenticationBox: authBox)
                    .value

                let filteredStatuses: [Mastodon.Entity.Status]
                if configuration.ignoreContentWarnings?.boolValue == true {
                    filteredStatuses = mostRecentStatuses
                } else {
                    filteredStatuses = mostRecentStatuses.filter { $0.sensitive == false }
                }

                if let mostRecentStatus = filteredStatuses.first {

                    let hashtagEntry = HashtagEntry(
                        accountName: mostRecentStatus.account.displayNameWithFallback,
                        account: mostRecentStatus.account.acct,
                        content: mostRecentStatus.content ?? "-",
                        reblogCount: mostRecentStatus.reblogsCount,
                        favoriteCount: mostRecentStatus.favouritesCount,
                        hashtag: "#\(desiredHashtag)",
                        timestamp: mostRecentStatus.createdAt
                    )

                    let hashtagTimelineEntry = HashtagWidgetTimelineEntry(
                        date: mostRecentStatus.createdAt,
                        hashtag: hashtagEntry
                    )

                    completion(hashtagTimelineEntry)
                } else {
                    let noStatusFound = HashtagWidgetTimelineEntry.notFound(desiredHashtag)

                    completion(noStatusFound)
                }
            } catch {
                completion(.notFound(desiredHashtag))
            }
        }



    }
}

struct HashtagWidgetTimelineEntry: TimelineEntry {
    var date: Date
    var hashtag: HashtagEntry

    static var placeholder: Self {
        HashtagWidgetTimelineEntry(
            date: .now,
            hashtag: HashtagEntry(
                accountName: L10n.Widget.Hashtag.Placeholder.accountName,
                account: L10n.Widget.Hashtag.Placeholder.account,
                content: L10n.Widget.Hashtag.Placeholder.content,
                reblogCount: 13,
                favoriteCount: 12,
                hashtag: "#hashtag",
                timestamp: .now.addingTimeInterval(-3600 * 12)
            )
        )
    }

    static func notFound(_ hashtag: String? = nil) -> Self {
        HashtagWidgetTimelineEntry(
            date: .now,
            hashtag: HashtagEntry(
                accountName: L10n.Widget.Hashtag.NotFound.accountName,
                account: L10n.Widget.Hashtag.NotFound.account,
                content: L10n.Widget.Hashtag.NotFound.content(hashtag ?? "hashtag"),
                reblogCount: 0,
                favoriteCount: 0,
                hashtag: hashtag ?? "",
                timestamp: .now
            )
        )
    }

    static var unconfigured: Self {
        HashtagWidgetTimelineEntry(
            date: .now,
            hashtag: HashtagEntry(
                accountName: "Unconfigured",
                account: "@unconfigured@mastodon.social",
                content: "Caturday is the best day of the week #CatsOfMastodon",
                reblogCount: 14,
                favoriteCount: 13,
                hashtag: "#CatsOfMastodon",
                timestamp: .now.addingTimeInterval(-3600 * 18)
            )
        )
    }
}

struct HashtagWidget: Widget {

    private var availableFamilies: [WidgetFamily] {
        return [.systemMedium, .systemLarge, .accessoryRectangular]
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "Hashtag", intent: HashtagIntent.self, provider: HashtagWidgetProvider()) { entry in
            HashtagWidgetView(entry: entry)
        }
        .configurationDisplayName(L10n.Widget.Hashtag.Configuration.displayName)
        .description(L10n.Widget.Hashtag.Configuration.description)
        .supportedFamilies(availableFamilies)
        .contentMarginsDisabled() // Disable excessive margins (only effective for iOS >= 17.0
    }
}

struct HashtagEntry {
    var accountName: String
    var account: String
    var content: String
    var reblogCount: Int
    var favoriteCount: Int
    var hashtag: String
    var timestamp: Date
}
