//
//  ManagedObjectObserver.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/8.
//

import Foundation
import CoreData
import Combine

final public class ManagedObjectObserver {
    private init() { }
}

extension ManagedObjectObserver {
    
    public static func observe(object: NSManagedObject) -> AnyPublisher<Change, Error> {
        guard let context = object.managedObjectContext else {
            return Fail(error: .noManagedObjectContext).eraseToAnyPublisher()
        }
        
        return NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .tryMap { notification in
                guard let notification = ManagedObjectContextObjectsDidChangeNotification(notification: notification) else {
                    throw Error.notManagedObjectChangeNotification
                }
                
                let changeType = ManagedObjectObserver.changeType(of: object, in: notification)
                return Change(
                    changeType: changeType,
                    changeNotification: notification
                )
            }
            .mapError { error -> Error in
                return (error as? Error) ?? .unknown(error)
            }
            .eraseToAnyPublisher()
    }
    
}

extension ManagedObjectObserver {
    private static func changeType(of object: NSManagedObject, in notification: ManagedObjectContextObjectsDidChangeNotification) -> ChangeType? {
        let deleted = notification.deletedObjects.union(notification.invalidedObjects)
        if notification.invalidatedAllObjects || deleted.contains(where: { $0 === object }) {
            return .delete
        }
        
        let updated = notification.updatedObjects.union(notification.refreshedObjects)
        if let object = updated.first(where: { $0 === object }) {
            return .update(object)
        }
        
        return nil
    }
}

extension ManagedObjectObserver {
    public struct Change {
        public let changeType: ChangeType?
        public let changeNotification: ManagedObjectContextObjectsDidChangeNotification
                
        init(changeType: ManagedObjectObserver.ChangeType?, changeNotification: ManagedObjectContextObjectsDidChangeNotification) {
            self.changeType = changeType
            self.changeNotification = changeNotification
        }
        
    }
    public enum ChangeType {
        case delete
        case update(NSManagedObject)
    }
    
    public enum Error: Swift.Error {
        case unknown(Swift.Error)
        case noManagedObjectContext
        case notManagedObjectChangeNotification
    }
}
