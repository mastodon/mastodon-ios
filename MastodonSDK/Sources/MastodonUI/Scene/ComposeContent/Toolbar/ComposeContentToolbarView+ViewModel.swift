//
//  ComposeContentToolbarView.swift
//  
//
//  Created by MainasuK on 22/10/18.
//

import SwiftUI
import MastodonCore
import MastodonAsset
import MastodonLocalization
import MastodonSDK

extension ComposeContentToolbarView {
    class ViewModel: ObservableObject {
        
        weak var delegate: ComposeContentToolbarViewDelegate?
        
        // input
        @Published var backgroundColor = ThemeService.shared.currentTheme.value.composeToolbarBackgroundColor
        @Published var suggestedLanguages: [String] = []
        @Published var highConfidenceSuggestedLanguage: String?
        @Published var visibility: Mastodon.Entity.Status.Visibility = .public
        var allVisibilities: [Mastodon.Entity.Status.Visibility] {
            return [.public, .private, .direct]
        }
        @Published var isVisibilityButtonEnabled = false
        @Published var isPollActive = false
        @Published var isEmojiActive = false
        @Published var isContentWarningActive = false
        
        @Published var isAttachmentButtonEnabled = false
        @Published var isPollButtonEnabled = false
        
        @Published var language = Locale.current.languageCode ?? "en"
        @Published var recentLanguages: [String] = []

        @Published public var maxTextInputLimit = 500
        @Published public var contentWeightedLength = 0
        @Published public var contentWarningWeightedLength = 0

        // output
        
        init(delegate: ComposeContentToolbarViewDelegate) {
            self.delegate = delegate
            // end init
            
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
        case language
    }
    
    enum AttachmentAction: CaseIterable {
        case photoLibrary
        case camera
        case browse
        
        var title: String {
            switch self {
            case .photoLibrary:     return L10n.Scene.Compose.MediaSelection.photoLibrary
            case .camera:           return L10n.Scene.Compose.MediaSelection.camera
            case .browse:           return L10n.Scene.Compose.MediaSelection.browse
            }
        }
        
        var image: UIImage {
            switch self {
            case .photoLibrary:     return UIImage(systemName: "photo.on.rectangle")!
            case .camera:           return UIImage(systemName: "camera")!
            case .browse:           return UIImage(systemName: "ellipsis")!
            }
        }
    }
}
