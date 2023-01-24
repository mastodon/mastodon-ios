// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI
import Intents

struct FollowersProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> FollowersEntry {
        FollowersEntry(date: Date(), configuration: FollowersCountIntent())
    }

    func getSnapshot(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (FollowersEntry) -> ()) {
        let entry = FollowersEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [FollowersEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = FollowersEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct FollowersEntry: TimelineEntry {
    let date: Date
    let configuration: FollowersCountIntent
}

struct FollowersWidgetExtensionEntryView : View {
    var entry: FollowersProvider.Entry

    var body: some View {
        Text(entry.date, style: .time)
    }
}

struct FollowersWidgetExtension: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "Followers", intent: FollowersCountIntent.self, provider: FollowersProvider()) { entry in
            FollowersWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Followers")
        .description("Show number of followers.")
    }
}

struct WidgetExtension_Previews: PreviewProvider {
    static var previews: some View {
        FollowersWidgetExtensionEntryView(entry: FollowersEntry(date: Date(), configuration: FollowersCountIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
