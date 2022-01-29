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
            children.append(element)
        }
        return UIMenu(title: "", options: [], children: children)
    }
}

extension MastodonMenu {
    public enum Action {
        case muteUser(MuteUserActionContext)
        case blockUser(BlockUserActionContext)
        case reportUser(ReportUserActionContext)
        case shareUser(ShareUserActionContext)
        case deleteStatus
        
        func build(delegate: MastodonMenuDelegate) -> UIMenuElement {
            switch self {
            case .muteUser(let context):
                let muteAction = UIAction(
                    title: context.isMuting ? L10n.Common.Controls.Friendship.unmuteUser(context.name) : L10n.Common.Controls.Friendship.muteUser(context.name),
                    image: context.isMuting ? UIImage(systemName: "speaker.wave.2") : UIImage(systemName: "speaker.slash"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off
                ) { [weak delegate] _ in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return muteAction
            case .blockUser(let context):
                let blockAction = UIAction(
                    title: context.isBlocking ? L10n.Common.Controls.Friendship.unblockUser(context.name) : L10n.Common.Controls.Friendship.blockUser(context.name),
                    image: context.isBlocking ? UIImage(systemName: "hand.raised") : UIImage(systemName: "hand.raised"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off
                ) { [weak delegate] _ in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return blockAction
            case .reportUser(let context):
                let reportAction = UIAction(
                    title: L10n.Common.Controls.Actions.reportUser(context.name),
                    image: UIImage(systemName: "flag"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off
                ) { [weak delegate] _ in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return reportAction
            case .shareUser(let context):
                let shareAction = UIAction(
                    title: L10n.Common.Controls.Actions.shareUser(context.name),
                    image: UIImage(systemName: "square.and.arrow.up"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off
                ) { [weak delegate] _ in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return shareAction
            case .deleteStatus:
                let deleteAction = UIAction(
                    title: L10n.Common.Controls.Actions.delete,
                    image: UIImage(systemName: "minus.circle"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: .destructive,
                    state: .off
                ) { [weak delegate] _ in
                    guard let delegate = delegate else { return }
                    delegate.menuAction(self)
                }
                return deleteAction
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
