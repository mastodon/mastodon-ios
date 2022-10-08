//
//  APIService+CoreData+MastodonAuthentication.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import os.log
import Foundation
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService.CoreData {
    
    public static func createOrMergeMastodonAuthentication(
        into managedObjectContext: NSManagedObjectContext,
        for authenticateMastodonUser: MastodonUser,
        in domain: String,
        property: MastodonAuthentication.Property,
        networkDate: Date
    ) -> (mastodonAuthentication: MastodonAuthentication, isCreated: Bool) {
        // fetch old mastodon authentication
        let oldMastodonAuthentication: MastodonAuthentication? = {
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(domain: domain, userID: property.userID)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        if let oldMastodonAuthentication = oldMastodonAuthentication {
            // merge old mastodon authentication
            APIService.CoreData.mergeMastodonAuthentication(
                for: authenticateMastodonUser,
                old: oldMastodonAuthentication,
                in: domain,
                property: property,
                networkDate: networkDate
            )
            return (oldMastodonAuthentication, false)
        } else {
            let mastodonAuthentication = MastodonAuthentication.insert(
                into: managedObjectContext,
                property: property,
                user: authenticateMastodonUser
            )
            return (mastodonAuthentication, true)
        }
    }
    
    static func mergeMastodonAuthentication(
        for authenticateMastodonUser: MastodonUser,
        old authentication: MastodonAuthentication,
        in domain: String,
        property: MastodonAuthentication.Property,
        networkDate: Date
    ) {
        guard networkDate > authentication.updatedAt else { return }
    
        
        authentication.update(username: property.username)
        authentication.update(appAccessToken: property.appAccessToken)
        authentication.update(userAccessToken: property.userAccessToken)
        authentication.update(clientID: property.clientID)
        authentication.update(clientSecret: property.clientSecret)
        
        authentication.didUpdate(at: networkDate)
    }
    
}
