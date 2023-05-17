//
//  SuggestionAccountTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-16.
//

import UIKit
import Combine
import CoreDataStack
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonMeta
import Meta

extension SuggestionAccountTableViewCell {

    func configure(user: MastodonUser) {
        //TODO: Set Delegate
        userView.configure(user: user, delegate: nil)
        //TODO: Fix Button State
        userView.setButtonState(.follow)

        let metaContent: MetaContent = {
            do {
                let mastodonContent = MastodonContent(content: user.note ?? "", emojis: [:])
                return try MastodonMetaContent.convert(document: mastodonContent)
            } catch {
                assertionFailure()
                return PlaintextMetaContent(string: user.note ?? "")
            }
        } ()
        
        bioMetaLabel.configure(content: metaContent)
    }
}
