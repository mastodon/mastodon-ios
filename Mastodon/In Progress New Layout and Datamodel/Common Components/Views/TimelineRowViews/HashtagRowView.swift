// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK

struct HashtagRowView: View {
    
    let tag: Mastodon.Entity.Tag
    
    var body: some View {
        Text("HASHTAG: \(tag.name)")
            .font(.title)
            .padding()
    }
}
