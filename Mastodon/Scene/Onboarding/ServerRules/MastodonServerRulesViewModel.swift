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
    let context: AppContext
    let domain: String
    let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
    let rules: [Mastodon.Entity.Instance.Rule]
    let registerQuery: Mastodon.API.Account.RegisterQuery
    let applicationAuthorization: Mastodon.API.OAuth.Authorization

    // output
    let isRegistering = CurrentValueSubject<Bool, Never>(false)
    let error = CurrentValueSubject<Error?, Never>(nil)

    
    init(
        context: AppContext,
        domain: String,
        authenticateInfo: AuthenticationViewModel.AuthenticateInfo,
        rules: [Mastodon.Entity.Instance.Rule],
        registerQuery: Mastodon.API.Account.RegisterQuery,
        applicationAuthorization: Mastodon.API.OAuth.Authorization
    ) {
        self.context = context
        self.domain = domain
        self.authenticateInfo = authenticateInfo
        self.rules = rules
        self.registerQuery = registerQuery
        self.applicationAuthorization = applicationAuthorization
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
