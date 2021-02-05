//
//  MastodonRegisterViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import Foundation
import Combine
import MastodonSDK

final class MastodonRegisterViewModel {
    
    // input
    let domain: String
    let applicationToken: Mastodon.Entity.Token
    let isRegistering = CurrentValueSubject<Bool, Never>(false)
    
    // output
    let applicationAuthorization: Mastodon.API.OAuth.Authorization
    let error = CurrentValueSubject<Error?, Never>(nil)

    init(domain: String, applicationToken: Mastodon.Entity.Token) {
        self.domain = domain
        self.applicationToken = applicationToken
        self.applicationAuthorization = Mastodon.API.OAuth.Authorization(accessToken: applicationToken.accessToken)
    }
    
}
