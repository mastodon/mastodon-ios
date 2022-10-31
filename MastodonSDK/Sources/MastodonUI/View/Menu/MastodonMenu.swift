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
        case muteUser(MuteUserActionContext)
        case blockUser(BlockUserActionContext)
        case reportUser(ReportUserActionContext)
        case shareUser(ShareUserActionContext)
        case deleteStatus
        
        func build(delegate: MastodonMenuDelegate) -> BuiltAction {
            switch self {
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
    
}
