// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI

struct HashtagWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> HashtagWidgetTimelineEntry {
        .init(date: Date())
    }

    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (HashtagWidgetTimelineEntry) -> Void) {
        //TODO: Implement
    }

    func getTimeline(for configuration: HashtagIntent, in context: Context, completion: @escaping (Timeline<HashtagWidgetTimelineEntry>) -> Void) {
        //TODO: Implement
    }
}

struct HashtagWidgetTimelineEntry: TimelineEntry {
    var date: Date
    //TODO: implement, add relevant information
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
            HashtagWidgetView()
        }
        .supportedFamilies(availableFamilies)
    }
}
