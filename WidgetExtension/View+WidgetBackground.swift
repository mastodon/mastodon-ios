// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import SwiftUI

extension View {
    func emptyWidgetBackground() -> some View {
        widgetBackground(EmptyView())
    }
    
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
