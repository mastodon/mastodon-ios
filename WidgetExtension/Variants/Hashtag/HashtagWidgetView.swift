// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct HashtagWidgetView: View {

    var entry: HashtagWidgetProvider.Entry
    
    var body: some View {
        //TODO: Lockscreen has a different design
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(entry.hashtag.accountName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text(entry.hashtag.account)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("18h") //TODO: Implement
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(entry.hashtag.content)
            Spacer()
            HStack(alignment: .center, spacing: 16) {
                HStack(spacing: 0) {
                    Image(systemName: "arrow.2.squarepath")
                        .foregroundColor(.secondary)
                    Text("\(entry.hashtag.reblogCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 0) {
                    Image(systemName: "star")
                        .foregroundColor(.secondary)
                    Text("\(entry.hashtag.favoriteCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(entry.hashtag.hashtag)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .padding(EdgeInsets(top: 12, leading: 29, bottom: 12, trailing: 29))
    }
}
