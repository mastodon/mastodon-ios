//
//  WelcomeContentPage.swift
//  Mastodon
//
//  Created by Nathan Mattes on 26.11.22.
//

import UIKit
import MastodonLocalization
import MastodonAsset

enum WelcomeContentPage: CaseIterable {
    case whatIsMastodon
    case mastodonIsLikeThat
    case howDoIPickAServer
    
    var backgroundColor: UIColor {
        switch self {
        case .whatIsMastodon:
            return .green
        case .mastodonIsLikeThat:
            return .red
        case .howDoIPickAServer:
            return .blue
        }
    }
    
    var title: NSAttributedString {
        switch self {
        case .whatIsMastodon:
            let image = Asset.Scene.Welcome.mastodonLogo.image
            let attachment = NSTextAttachment(image: image)
            let attributedString = NSMutableAttributedString(string: "\(L10n.Scene.Welcome.Education.WhatIsMastodon.title) ")

            attachment.bounds = CGRect(
                x: 0,
                y: WelcomeViewController.largeTitleFont.descender - 5,
                width: image.size.width,
                height: image.size.height
            )
          
            attributedString.append(NSAttributedString(attachment: attachment))
            attributedString.append(NSAttributedString(string: " ?"))
            return attributedString
        case .mastodonIsLikeThat:
            return NSAttributedString(string: L10n.Scene.Welcome.Education.MastodonIsLikeThat.title)
        case .howDoIPickAServer:
            return NSAttributedString(string: L10n.Scene.Welcome.Education.HowDoIPickAServer.title)
        }
    }
    
    var content: String {
        switch self {
        case .whatIsMastodon:
            return L10n.Scene.Welcome.Education.WhatIsMastodon.description
        case .mastodonIsLikeThat:
            return L10n.Scene.Welcome.Education.MastodonIsLikeThat.description
        case .howDoIPickAServer:
            return L10n.Scene.Welcome.Education.HowDoIPickAServer.description
        }
        
    }
}
