// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI

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
        let hashtagTimelineEntry = HashtagWidgetTimelineEntry.placeholder
        completion(hashtagTimelineEntry)
    }
}

struct HashtagWidgetTimelineEntry: TimelineEntry {
    var date: Date
    //TODO: implement, add relevant information
    var hashtag: HashtagEntry

    static var placeholder: Self {
        HashtagWidgetTimelineEntry(
            date: .now,
            hashtag: HashtagEntry(
                accountName: "John Mastodon",
                account: "@johnmastodon@mastodon.social",
                content: "Caturday is the best day of the week #CatsOfMastodon",
                reblogCount: 13,
                favoriteCount: 12,
                hashtag: "#CatsOfMastodon")
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
        .configurationDisplayName("Hashtag")
        .description("Show a Hashtag")
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
}
