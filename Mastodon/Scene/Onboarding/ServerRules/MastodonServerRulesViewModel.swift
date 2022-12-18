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
}
