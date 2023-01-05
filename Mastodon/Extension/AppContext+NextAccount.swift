//
//  AppContext+NextAccount.swift
//  Mastodon
//
//  Created by Marcus Kida on 17.11.22.
//

import CoreData
import CoreDataStack
import MastodonCore
import MastodonSDK

extension AppContext {
    func nextAccount(in authContext: AuthContext) -> MastodonAuthentication? {
        let request = MastodonAuthentication.sortedFetchRequest
        guard
            let accounts = try? managedObjectContext.fetch(request),
            accounts.count > 1
        else { return nil }
        
        let nextSelectedAccountIndex: Int? = {
            for (index, account) in accounts.enumerated() {
                guard account == authContext.mastodonAuthenticationBox
                    .authenticationRecord
                    .object(in: managedObjectContext)
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
