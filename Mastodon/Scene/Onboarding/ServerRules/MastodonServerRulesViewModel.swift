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
        for (i, rule) in rules.enumerated() {
            let index = String(i + 1)
            let indexString = NSAttributedString(string: index + ". ", attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
            ])
            let ruleString = NSAttributedString(string: rule.text + "\n\n")
            attributedString.append(indexString)
            attributedString.append(ruleString)
        }
        return attributedString
    }
    
}
