//
//  MastodonAuthentication.swift
//  MastodonIntent
//
//  Created by MainasuK on 2022-6-9.
//

import Foundation
import CoreData
import CoreDataStack

extension MastodonAuthentication {
    
    static func fetch(in managedObjectContext: NSManagedObjectContext) throws -> [MastodonAuthentication] {
        let request = MastodonAuthentication.sortedFetchRequest
        let results = try managedObjectContext.fetch(request)
        return results
    }
    
}
