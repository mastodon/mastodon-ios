// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI
import MastodonSDK
import MastodonLocalization

struct HashtagWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> HashtagWidgetTimelineEntry {
        .placeholder
    }

    func getSnapshot(for configuration: HashtagIntent, in context: Context, completion: @escaping (HashtagWidgetTimelineEntry) -> Void) {
        loadMostRecentHashtag(for: configuration, in: context, completion: completion)
    }

    func getTimeline(for configuration: HashtagIntent, in context: Context, completion: @escaping (Timeline<HashtagWidgetTimelineEntry>) -> Void) {
        loadMostRecentHashtag(for: configuration, in: context) { entry in
            completion(Timeline(entries: [entry], policy: .after(.now)))
        }
    }
}

extension HashtagWidgetProvider {
    func loadMostRecentHashtag(for configuration: HashtagIntent, in context: Context, completion: @escaping (HashtagWidgetTimelineEntry) -> Void ) {

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

        Task {
            let desiredHashtag: String

            if let hashtag = configuration.hashtag {
                desiredHashtag = hashtag
            } else {
                return completion(.notFound)
            }

            do {
                let mostRecentStatuses = try await WidgetExtension.appContext
                    .apiService
                    .hashtagTimeline(domain: authBox.domain, limit: 1, hashtag: desiredHashtag, authenticationBox: authBox)
                    .value

                if let mostRecentStatus = mostRecentStatuses.first {

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
                }
            } catch {
                completion(.notFound)
            }
        }



    }
}

struct HashtagWidgetTimelineEntry: TimelineEntry {
    var date: Date
    var hashtag: HashtagEntry

    static var placeholder: Self {
        //TODO: @zeitschlag Add Localization
        HashtagWidgetTimelineEntry(
            date: .now,
            hashtag: HashtagEntry(
                accountName: "John Mastodon",
                account: "@johnmastodon@mastodon.social",
                content: "Caturday is the best day of the week #CatsOfMastodon",
                reblogCount: 13,
                favoriteCount: 12,
                hashtag: "#CatsOfMastodon",
                timestamp: .now.addingTimeInterval(-3600 * 18)
            )
        )
    }

    static var notFound: Self {
        HashtagWidgetTimelineEntry(
            date: .now,
            hashtag: HashtagEntry(
                accountName: "Not Found",
                account: "404",
                content: "Couldn't find a status, sorryyyyyyy",
                reblogCount: 0,
                favoriteCount: 0,
                hashtag: "",
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
        if #available(iOS 16, *) {
            return [.systemMedium, .systemLarge, .accessoryRectangular]
        } else {
            return [.systemMedium, .systemLarge]
        }
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "Hashtag", intent: HashtagIntent.self, provider: HashtagWidgetProvider()) { entry in
            HashtagWidgetView(entry: entry)
        }
        .configurationDisplayName(L10n.Widget.Hashtag.Configuration.displayName)
        .description(L10n.Widget.Hashtag.Configuration.description)
        .supportedFamilies(availableFamilies)
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
