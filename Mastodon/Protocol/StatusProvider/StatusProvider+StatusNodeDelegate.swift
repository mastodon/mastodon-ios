//
//  StatusProvider+StatusNodeDelegate.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-20.
//

#if ASDK

import Foundation
import ActiveLabel

// MARK: - StatusViewDelegate
extension StatusNodeDelegate where Self: StatusProvider {
    func statusNode(_ node: StatusNode, statusContentTextNode: ASMetaEditableTextNode, didSelectActiveEntityType type: ActiveEntityType) {
        StatusProviderFacade.responseToStatusActiveLabelAction(provider: self, node: node, didSelectActiveEntityType: type)
    }
}

#endif
