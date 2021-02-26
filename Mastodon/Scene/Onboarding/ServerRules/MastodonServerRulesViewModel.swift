//
//  MastodonServerRulesViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-22.
//

import UIKit
import MastodonSDK

final class MastodonServerRulesViewModel {
    
    // input
    let context: AppContext
    let domain: String
    let rules: [Mastodon.Entity.Instance.Rule]
    
    init(context: AppContext, domain: String, rules: [Mastodon.Entity.Instance.Rule]) {
        self.context = context
        self.domain = domain
        self.rules = rules
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
        // let paragraphStyle = NSMutableParagraphStyle()
        // paragraphStyle.lineSpacing = 20
        // attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }
    
}
