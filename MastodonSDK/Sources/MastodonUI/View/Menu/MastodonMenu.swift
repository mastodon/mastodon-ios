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

            let element: UIMenuElement
            
            if case let .deleteStatus = action {
                let deleteAction = action.build(delegate: delegate).menuElement
                element = UIMenu(options: .displayInline, children: [deleteAction])
            } else {
                element = action.build(delegate: delegate).menuElement
            }
            children.append(element)
        }
        return UIMenu(options: .displayInline, children: children)
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

    public static func setupAlertActions(
        actions: [Action],
        delegate: MastodonMenuDelegate
    ) -> [UIAlertAction] {
        var alertActions: [UIAlertAction] = []
        for action in actions {
            let element = action.build(delegate: delegate)
            alertActions.append(element.alertAction)
        }
        return alertActions

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
        case editStatus
        case showActionSheet(title: String, actions: [UIAlertAction])

        func build(delegate: MastodonMenuDelegate) -> LabeledAction {
            switch self {
            case .hideReblogs(let context):
                let title = context.showReblogs ? L10n.Common.Controls.Friendship.hideReblogs : L10n.Common.Controls.Friendship.showReblogs
                let reblogAction = LabeledAction(title: title, image: UIImage(systemName: "arrow.2.squarepath")) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }

                return reblogAction
            case .muteUser(let context):
                let title: String
                let image: UIImage?
                if context.isMuting {
                    title = L10n.Common.Controls.Friendship.unmuteUser(context.name)
                    image = UIImage(systemName: "speaker.wave.2")
                } else {
                    title = L10n.Common.Controls.Friendship.muteUser(context.name)
                    image = UIImage(systemName: "speaker.slash")
                }
                let muteAction = LabeledAction(title: title, image: image) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return muteAction
            case .blockUser(let context):
                let title: String
                let image: UIImage?
                if context.isBlocking {
                    title = L10n.Common.Controls.Friendship.unblockUser(context.name)
                    image = UIImage(systemName: "hand.raised.slash")
                } else {
                    title = L10n.Common.Controls.Friendship.blockUser(context.name)
                    image = UIImage(systemName: "hand.raised")
                }
                let blockAction = LabeledAction(title: title, image: image) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return blockAction
            case .reportUser(let context):
                let reportAction = LabeledAction(
                    title: L10n.Common.Controls.Actions.reportUser(context.name),
                    image: UIImage(systemName: "flag")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return reportAction
            case .shareUser(let context):
                let shareAction = LabeledAction(
                    title: L10n.Common.Controls.Actions.shareUser(context.name),
                    image: UIImage(systemName: "square.and.arrow.up")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return shareAction
            case .bookmarkStatus(let context):
                let title: String
                let image: UIImage?
                if context.isBookmarking {
                    title = "Remove Bookmark" // TODO: i18n
                    image = UIImage(systemName: "bookmark.slash.fill")
                } else {
                    title = "Bookmark" // TODO: i18n
                    image = UIImage(systemName: "bookmark")
                }
                let action = LabeledAction(title: title, image: image) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return action
            case .shareStatus:
                let action = LabeledAction(
                    title: "Share",      // TODO: i18n
                    image: UIImage(systemName: "square.and.arrow.up")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return action
            case .deleteStatus:
                let deleteAction = LabeledAction(
                    title: L10n.Common.Controls.Actions.delete,
                    image: UIImage(systemName: "minus.circle"),
                    attributes: .destructive
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return deleteAction
            case let .translateStatus(context):
                let language = Locale.current.localizedString(forIdentifier: context.language) ?? L10n.Common.Controls.Actions.TranslatePost.unknownLanguage
                let translateAction = LabeledAction(
                    title: L10n.Common.Controls.Actions.TranslatePost.title(language),
                    image: UIImage(systemName: "character.book.closed")
                ) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return translateAction
            case .editStatus:
                let editStatusAction = LabeledAction(
                    title: L10n.Common.Controls.Actions.editPost,
                    image: UIImage(systemName: "pencil")
                ) {
                    [weak delegate] in
                    guard let delegate else { return }
                    delegate.menuAction(self)
                }

                return editStatusAction
            case let .showActionSheet(title, _):
                let showMoreAction = LabeledAction(title: title) { [weak delegate] in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return showMoreAction
            }   // end switch
        }   // end func build
    }   // end enum Action
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
