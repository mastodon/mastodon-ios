// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import WidgetKit
import SwiftUI

@main
struct WidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        FollowersCountWidget()
        MultiFollowersCountWidget()
        LatestFollowersWidget()
        HashtagWidget()
    }
}
