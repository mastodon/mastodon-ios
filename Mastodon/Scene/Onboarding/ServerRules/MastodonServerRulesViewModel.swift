//
//  MastodonServerRulesViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-22.
//

import UIKit
import Combine
import MastodonSDK
import MastodonAsset
import MastodonLocalization

final class MastodonServerRulesViewModel {
    
    // input
    let domain: String
    let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
    let rules: [Mastodon.Entity.Instance.Rule]
    let instance: Mastodon.Entity.Instance
    let applicationToken: Mastodon.Entity.Token
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ServerRuleSection, ServerRuleItem>?
    
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
        let separatorString = Array(repeating: " ", count: 4).joined()
        for (i, rule) in rules.enumerated() {
            guard i < 50 else {
                return NSAttributedString(string: "\(i)" + separatorString + rule.text.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n")
            }
            let imageName = String(i + 1) + ".circle"
            let image = UIImage(systemName: imageName, withConfiguration: configuration)!
            let attachment = NSTextAttachment()
            attachment.image = image.withTintColor(Asset.Colors.brand.color)
            let imageAttribute = NSMutableAttributedString(attachment: attachment)
            imageAttribute.addAttributes([NSAttributedString.Key.baselineOffset : -1.5], range: NSRange(location: 0, length: imageAttribute.length))
        
            let ruleString = NSAttributedString(string: separatorString + rule.text.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n")
            attributedString.append(imageAttribute)
            attributedString.append(ruleString)
        }
        return attributedString
    }
    
}
