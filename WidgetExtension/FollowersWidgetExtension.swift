// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI
import Intents
import MastodonSDK

struct FollowersProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> FollowersEntry {
        .empty(with: FollowersCountIntent())
    }

    func getSnapshot(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (FollowersEntry) -> ()) {
        loadCurrentEntry(for: configuration, in: context, completion: completion)
    }

    func getTimeline(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        loadCurrentEntry(for: configuration, in: context) { entry in
            completion(Timeline(entries: [entry], policy: .after(.now)))
        }
    }
}

struct FollowersEntry: TimelineEntry {
    let date: Date
    let account: Mastodon.Entity.Account?
    let avatarImage: UIImage?
    let configuration: FollowersCountIntent
    
    static func empty(with configuration: FollowersCountIntent) -> Self {
        FollowersEntry(date: .now, account: nil, avatarImage: nil, configuration: configuration)
    }
}

struct FollowersWidgetExtensionEntryView : View {
    var entry: FollowersProvider.Entry

    var body: some View {
        if let account = entry.account {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    if let avatarImage = entry.avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(12)
                            .padding(.bottom, 8)
                    }
                    
                    Text(account.followersCount.asAbbreviatedCountString())
                        .font(.largeTitle)
                        .lineLimit(1)
                        .truncationMode(.tail)
                
                    Text("\(account.displayNameWithFallback)")
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("@\(account.acct)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.leading, 20)
                .padding([.top, .bottom], 16)
                Spacer()
            }
        } else {
            Text("Please use the Widget settings to select an Account.")
        }
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
        FollowersWidgetExtensionEntryView(entry: FollowersEntry(
            date: Date(),
            account: nil,
            avatarImage: nil,
            configuration: FollowersCountIntent())
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

private extension FollowersProvider {
    func loadCurrentEntry(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (FollowersEntry) -> Void) {
        Task {
            guard
                let authBox = WidgetExtension.appContext
                    .authenticationService
                    .mastodonAuthenticationBoxes
                    .first,
                let account = configuration.account
            else {
                return completion(.empty(with: configuration))
            }
            let resultingAccount = try await WidgetExtension.appContext
                .apiService
                .search(query: .init(q: account, type: .accounts), authenticationBox: authBox)
                .value
                .accounts
                .first
            
            let image: UIImage? = try await {
                guard
                    let account = resultingAccount
                else {
                    return nil
                }
                
                let imageData = try await URLSession.shared.data(from: account.avatarImageURLWithFallback(domain: authBox.domain)).0

                return UIImage(data: imageData)
            }()
                        
            let entry = FollowersEntry(
                date: Date(),
                account: resultingAccount,
                avatarImage: image,
                configuration: configuration
            )
            completion(entry)
        }
    }
}
