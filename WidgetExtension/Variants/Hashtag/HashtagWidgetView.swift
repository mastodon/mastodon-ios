// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct HashtagWidgetView: View {
    var body: some View {
        //TODO: Lockscreen has a different design
        VStack {
            HStack {
                Text("Username")
                Text("@user@mastodon.social")
            }
            Text("Toot")
            HStack {
                Image(systemName: "arrow.2.squarepath")
                Text("Reblog Count")
                Image(systemName: "star")
                Text("Star Count")
                Text("#Hashtag")
            }
        }
    }
}
