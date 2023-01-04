//
//  MastodonMenu.swift
//  
//
//  Created by MainasuK on 2022-1-26.
//

import UIKit
import MastodonLocalization

public protocol MastodonMenuDelegate: AnyObject {
    func menuAction(_ action: MastodonMenu.Action)
}

public enum MastodonMenu {
    public static func setupMenu(
        actions: [Action],
        delegate: MastodonMenuDelegate
    ) -> UIMenu {
        var children: [UIMenuElement] = []
        for action in actions {
            let element = action.build(delegate: delegate)
            children.append(element.menuElement)
        }
        return UIMenu(title: "", options: [], children: children)
    }

    public static func setupAccessibilityActions(
        actions: [Action],
        delegate: MastodonMenuDelegate
    ) -> [UIAccessibilityCustomAction] {
        var accessibilityActions: [UIAccessibilityCustomAction] = []
        for action in actions {
            let element = action.build(delegate: delegate)
            accessibilityActions.append(element.accessibilityCustomAction)
        }
        return accessibilityActions
    }
}

extension MastodonMenu {
    public enum Action {
        case translateStatus(TranslateStatusActionContext)
        case muteUser(MuteUserActionContext)
        case blockUser(BlockUserActionContext)
        case reportUser(ReportUserActionContext)
        case shareUser(ShareUserActionContext)
        case bookmarkStatus(BookmarkStatusActionContext)
        case hideReblogs(HideReblogsActionContext)
        case shareStatus
        case deleteStatus
        
        func build(delegate: MastodonMenuDelegate) -> BuiltAction {
            switch self {
            case .hideReblogs(let context):
                let title = context.showReblogs ? L10n.Common.Controls.Friendship.hideReblogs : L10n.Common.Controls.Friendship.showReblogs
                let reblogAction = BuiltAction(
                    title: title,
                    image: UIImage(systemName: "arrow.2.squarepath")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }

                return reblogAction
            case .muteUser(let context):
                let muteAction = BuiltAction(
                    title: context.isMuting ? L10n.Common.Controls.Friendship.unmuteUser(context.name) : L10n.Common.Controls.Friendship.muteUser(context.name),
                    image: context.isMuting ? UIImage(systemName: "speaker.wave.2") : UIImage(systemName: "speaker.slash")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return muteAction
            case .blockUser(let context):
                let blockAction = BuiltAction(
                    title: context.isBlocking ? L10n.Common.Controls.Friendship.unblockUser(context.name) : L10n.Common.Controls.Friendship.blockUser(context.name),
                    image: context.isBlocking ? UIImage(systemName: "hand.raised") : UIImage(systemName: "hand.raised")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return blockAction
            case .reportUser(let context):
                let reportAction = BuiltAction(
                    title: L10n.Common.Controls.Actions.reportUser(context.name),
                    image: UIImage(systemName: "flag")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return reportAction
            case .shareUser(let context):
                let shareAction = BuiltAction(
                    title: L10n.Common.Controls.Actions.shareUser(context.name),
                    image: UIImage(systemName: "square.and.arrow.up")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return shareAction
            case .bookmarkStatus(let context):
                let action = BuiltAction(
                    title: context.isBookmarking ? "Remove Bookmark" : "Bookmark",      // TODO: i18n
                    image: context.isBookmarking ? UIImage(systemName: "bookmark.slash.fill") : UIImage(systemName: "bookmark")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return action
            case .shareStatus:
                let action = BuiltAction(
                    title: "Share",      // TODO: i18n
                    image: UIImage(systemName: "square.and.arrow.up")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return action
            case .deleteStatus:
                let deleteAction = BuiltAction(
                    title: L10n.Common.Controls.Actions.delete,
                    image: UIImage(systemName: "minus.circle"),
                    attributes: .destructive
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return deleteAction
            case let .translateStatus(context):
                let translateAction = BuiltAction(
                    title: L10n.Common.Controls.Actions.TranslatePost.title(Locale.current.localizedString(forIdentifier: context.language) ?? L10n.Common.Controls.Actions.TranslatePost.unknownLanguage),
                    image: UIImage(systemName: "character.book.closed")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return translateAction
            }   // end switch
        }   // end func build
    }   // end enum Action

    struct BuiltAction {
        init(
            title: String,
            image: UIImage? = nil,
            attributes: UIMenuElement.Attributes = [],
            state: UIMenuElement.State = .off,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.image = image
            self.attributes = attributes
            self.state = state
            self.handler = handler
        }

        let title: String
        let image: UIImage?
        let attributes: UIMenuElement.Attributes
        let state: UIMenuElement.State
        let handler: () -> Void

        var menuElement: UIMenuElement {
            UIAction(
                title: title,
                image: image,
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: attributes,
                state: .off
            ) { _ in
                handler()
            }
        }

        var accessibilityCustomAction: UIAccessibilityCustomAction {
            UIAccessibilityCustomAction(name: title, image: image) { _ in
                handler()
                return true
            }
        }
    }
}

extension MastodonMenu {
    public struct MuteUserActionContext {
        public let name: String
        public let isMuting: Bool
        
        public init(name: String, isMuting: Bool) {
            self.name = name
            self.isMuting = isMuting
        }
    }
    
    public struct BlockUserActionContext {
        public let name: String
        public let isBlocking: Bool
        
        public init(name: String, isBlocking: Bool) {
            self.name = name
            self.isBlocking = isBlocking
        }
    }
    
    public struct BookmarkStatusActionContext {
        public let isBookmarking: Bool
        
        public init(isBookmarking: Bool) {
            self.isBookmarking = isBookmarking
        }
    }
    
    public struct ReportUserActionContext {
        public let name: String
        
        public init(name: String) {
            self.name = name
        }
    }
    
    public struct ShareUserActionContext {
        public let name: String
        
        public init(name: String) {
            self.name = name
        }
    }

    public struct HideReblogsActionContext {
        public let showReblogs: Bool

        public init(showReblogs: Bool) {
            self.showReblogs = showReblogs
        }
    }
    
    public struct TranslateStatusActionContext {
        public let language: String
        
        public init(language: String) {
            self.language = language
        }
    }
}
