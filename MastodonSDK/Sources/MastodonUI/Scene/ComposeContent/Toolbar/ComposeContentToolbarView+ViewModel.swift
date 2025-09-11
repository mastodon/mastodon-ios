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
        @Published var backgroundColor = SystemTheme.composeToolbarBackgroundColor
        @Published var suggestedLanguages: [String] = []
        @Published var highConfidenceSuggestedLanguage: String?
        @Published var isPollActive = false
        @Published var isEmojiActive = false
        @Published var isContentWarningActive = false
        
        @Published var isAttachmentButtonEnabled = false
        @Published var isPollButtonEnabled = false
        
        @Published var language = UserDefaults.shared.defaultPostLanguage
        @Published var recentLanguages: [String] = []

        @Published public var maxTextInputLimit = 500
        @Published public var contentWeightedLength = 0
        @Published public var contentWarningWeightedLength = 0

        // output
        
        init(delegate: ComposeContentToolbarViewDelegate) {
            self.delegate = delegate
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
        
        var activeImage: UIImage {
            switch self {
            case .attachment:
                return Asset.Scene.Compose.media.image.withRenderingMode(.alwaysTemplate)
            case .poll:
                return Asset.Scene.Compose.pollFill.image.withRenderingMode(.alwaysTemplate)
            case .emoji:
                return Asset.Scene.Compose.emojiFill.image.withRenderingMode(.alwaysTemplate)
            case .contentWarning:
                return Asset.Scene.Compose.chatWarningFill.image.withRenderingMode(.alwaysTemplate)
            case .visibility:
                return Mastodon.Entity.Status.Visibility.public.image.withRenderingMode(.alwaysTemplate)
            case .language:
                fatalError("Language’s active image is never accessed")
            }
        }
        
        var inactiveImage: UIImage {
            switch self {
            case .attachment:
                return Asset.Scene.Compose.media.image.withRenderingMode(.alwaysTemplate)
            case .poll:
                return Asset.Scene.Compose.poll.image.withRenderingMode(.alwaysTemplate)
            case .emoji:
                return Asset.Scene.Compose.emoji.image.withRenderingMode(.alwaysTemplate)
            case .contentWarning:
                return Asset.Scene.Compose.chatWarning.image.withRenderingMode(.alwaysTemplate)
            case .visibility:
                return Mastodon.Entity.Status.Visibility.public.image
            case .language:
                fatalError("Language’s inactive image is never accessed")
            }
        }
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

extension ComposeContentToolbarView.ViewModel {
    func image(for action: Action) -> UIImage {
        switch action {
        case .poll:
            return isPollActive ? action.activeImage : action.inactiveImage
        case .emoji:
            return isEmojiActive ? action.activeImage : action.inactiveImage
        case .contentWarning:
            return isContentWarningActive ? action.activeImage : action.inactiveImage
        case .language:
            fatalError("Language’s image is never accessed")
        default:
            return action.inactiveImage
        }
    }

    func label(for action: Action) -> String {
        switch action {
        case .attachment:
            return L10n.Scene.Compose.Accessibility.appendAttachment
        case .poll:
            return isPollActive ? L10n.Scene.Compose.Accessibility.removePoll : L10n.Scene.Compose.Accessibility.appendPoll
        case .emoji:
            return L10n.Scene.Compose.Accessibility.customEmojiPicker
        case .contentWarning:
            return isContentWarningActive ? L10n.Scene.Compose.Accessibility.disableContentWarning : L10n.Scene.Compose.Accessibility.enableContentWarning
        case .visibility:
            return L10n.Scene.Compose.Accessibility.postVisibilityMenu
        case .language:
            return "[[language]]"
        }
    }
}
