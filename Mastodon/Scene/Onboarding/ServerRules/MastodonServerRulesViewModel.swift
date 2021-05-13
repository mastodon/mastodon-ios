//
//  MastodonServerRulesViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-22.
//

import UIKit
import Combine
import MastodonSDK

final class MastodonServerRulesViewModel {
    // input

    let domain: String
    let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
    let rules: [Mastodon.Entity.Instance.Rule]
    let instance: Mastodon.Entity.Instance
    let applicationToken: Mastodon.Entity.Token

    
    init(
        domain: String,
        authenticateInfo: AuthenticationViewModel.AuthenticateInfo,
        rules: [Mastodon.Entity.Instance.Rule],
        instance: Mastodon.Entity.Instance,
        applicationToken: Mastodon.Entity.Token
    ) {
        self.domain = domain
        self.authenticateInfo = authenticateInfo
        self.rules = rules
        self.instance = instance
        self.applicationToken = applicationToken
    }
    
    var rulesAttributedString: NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "\n")
        let configuration = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title3))
        for (i, rule) in rules.enumerated() {
            let imageName = String(i + 1) + ".circle.fill"
            let image = UIImage(systemName: imageName, withConfiguration: configuration)!
            let attachment = NSTextAttachment()
            attachment.image = image.withTintColor(Asset.Colors.Label.primary.color)
            let imageAttribute = NSAttributedString(attachment: attachment)

            let ruleString = NSAttributedString(string: "  " + rule.text + "\n\n")
            attributedString.append(imageAttribute)
            attributedString.append(ruleString)
        }
        return attributedString
    }
    
}
