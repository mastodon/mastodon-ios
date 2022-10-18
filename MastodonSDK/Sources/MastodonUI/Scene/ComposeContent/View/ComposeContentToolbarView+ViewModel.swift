//
//  ComposeContentToolbarView.swift
//  
//
//  Created by MainasuK on 22/10/18.
//

import SwiftUI
import MastodonCore
import MastodonAsset
import MastodonSDK

extension ComposeContentToolbarView {
    class ViewModel: ObservableObject {
        
        // input
        @Published var backgroundColor = ThemeService.shared.currentTheme.value.composeToolbarBackgroundColor
        @Published var visibility: Mastodon.Entity.Status.Visibility = .public
        var allVisibilities: [Mastodon.Entity.Status.Visibility] {
            return [.public, .private, .direct]
        }
        
        // output
        
        init() {
            ThemeService.shared.currentTheme
                .map { $0.composeToolbarBackgroundColor }
                .assign(to: &$backgroundColor)
        }
        
    }
}

extension ComposeContentToolbarView.ViewModel {
    enum Action: CaseIterable {
        case attachment
        case poll
        case emoji
        case contentWarning
        case visibility
        
        var image: UIImage {
            switch self {
            case .attachment:
                return Asset.Scene.Compose.media.image
            case .poll:
                return Asset.Scene.Compose.poll.image
            case .emoji:
                return Asset.Scene.Compose.emoji.image
            case .contentWarning:
                return Asset.Scene.Compose.chatWarning.image
            case .visibility:
                return Asset.Scene.Compose.earth.image
            }
        }
    }
}
