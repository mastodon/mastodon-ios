// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct NavigationTitleWithSubtitle: ViewModifier {
    let title: String
    let subtitle: String
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .navigationTitle(title)
                .navigationSubtitle(subtitle)
        } else {
            content
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text(title)
                                .font(.headline)
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
        }
    }
}

extension View {
    func navigationTitle(_ title: String, withSubtitle subtitle: String) -> some View {
        modifier(NavigationTitleWithSubtitle(title: title, subtitle: subtitle))
    }
}
