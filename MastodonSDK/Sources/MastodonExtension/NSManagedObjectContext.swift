//
//  NSManagedObjectContext.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    public func safeFetch<T>(_ request: NSFetchRequest<T>) -> [T] where T : NSFetchRequestResult {
        do {
            return try fetch(request)
        } catch {
            assertionFailure(error.localizedDescription)
            return []
        }
    }
}
