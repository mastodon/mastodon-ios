//
//  PrivacyViewModel.swift
//  Mastodon
//
//  Created by Nathan Mattes on 16.12.22.
//

import Foundation
import MastodonSDK

final class PrivacyViewModel {

    // input
    let domain: String
    let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
    let rows: [PrivacyRow]
    let instance: Mastodon.Entity.Instance
    let applicationToken: Mastodon.Entity.Token

    init(
        domain: String,
        authenticateInfo: AuthenticationViewModel.AuthenticateInfo,
        rows: [PrivacyRow],
        instance: Mastodon.Entity.Instance,
        applicationToken: Mastodon.Entity.Token
    ) {
        self.domain = domain
        self.authenticateInfo = authenticateInfo
        self.rows = rows
        self.instance = instance
        self.applicationToken = applicationToken
    }
}
