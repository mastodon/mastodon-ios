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

    func getTimeline(for configuration: FollowersCountIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
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

struct FollowersWidgetExtensionEntryView : View {
    var entry: FollowersProvider.Entry

    var body: some View {
        if let account = entry.account {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    if let avatarImage = account.avatarImage {
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
                
                    Text(account.displayNameWithFallback)
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
                .multilineTextAlignment(.center)
                .font(.caption)
                .padding(.all, 20)
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
        .supportedFamilies([.systemSmall])
    }
}

struct WidgetExtension_Previews: PreviewProvider {
    static var previews: some View {
        FollowersWidgetExtensionEntryView(entry: FollowersEntry(
            date: Date(),
            account: nil,
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
                return completion(.unconfigured)
            }
            let resultingAccount = try await WidgetExtension.appContext
                .apiService
                .search(query: .init(q: account, type: .accounts), authenticationBox: authBox)
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
