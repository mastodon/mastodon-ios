//
//  AuthContext.swift
//  
//
//  Created by MainasuK on 22/10/8.
//

import Foundation
import Combine
import CoreDataStack
import MastodonSDK

public protocol AuthContextProvider {
    var authContext: AuthContext { get }
}

public class AuthContext {
    
    var disposeBag = Set<AnyCancellable>()
    
    // Mastodon
    public private(set) var mastodonAuthenticationBox: MastodonAuthenticationBox

    private init(mastodonAuthenticationBox: MastodonAuthenticationBox) {
        self.mastodonAuthenticationBox = mastodonAuthenticationBox
    }
}

extension AuthContext {

    public convenience init?(authentication: MastodonAuthentication) {
        self.init(mastodonAuthenticationBox: MastodonAuthenticationBox(authentication: authentication))
    }

}
