//
//  AppContext+NextAccount.swift
//  Mastodon
//
//  Created by Marcus Kida on 17.11.22.
//

import MastodonCore
import MastodonSDK

extension AppContext {
    func nextAccount(in authContext: AuthContext) -> MastodonAuthentication? {
        let accounts = AuthenticationServiceProvider.shared.authentications
        guard accounts.count > 1 else { return nil }
        
        let nextSelectedAccountIndex: Int? = {
            for (index, account) in accounts.enumerated() {
                guard account == authContext.mastodonAuthenticationBox
                    .authentication
                else { continue }
                
                let nextAccountIndex = index + 1
                
                if accounts.count > nextAccountIndex {
                    return nextAccountIndex
                } else {
                    return 0
                }
            }
            
            return nil
        }()
        
        guard
            let nextSelectedAccountIndex = nextSelectedAccountIndex,
            accounts.count > nextSelectedAccountIndex
        else { return nil }
        
        return accounts[nextSelectedAccountIndex]
    }
}
