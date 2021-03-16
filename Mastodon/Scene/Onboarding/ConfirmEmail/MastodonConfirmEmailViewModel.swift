//
//  MastodonConfirmEmailViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/23.
//

import Combine
import Foundation
import MastodonSDK

final class MastodonConfirmEmailViewModel {
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    var email: String
    let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
    let userToken: Mastodon.Entity.Token
    let updateCredentialQuery: Mastodon.API.Account.UpdateCredentialQuery

    let timestampUpdatePublisher = Timer.publish(every: 4.0, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()

    init(
        context: AppContext,
        email: String,
        authenticateInfo: AuthenticationViewModel.AuthenticateInfo,
        userToken: Mastodon.Entity.Token,
        updateCredentialQuery: Mastodon.API.Account.UpdateCredentialQuery
    ) {
        self.context = context
        self.email = email
        self.authenticateInfo = authenticateInfo
        self.userToken = userToken
        self.updateCredentialQuery = updateCredentialQuery
    }
}
