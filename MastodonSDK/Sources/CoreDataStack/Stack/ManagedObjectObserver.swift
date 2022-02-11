//
//  ManagedObjectObserver.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-6-12.
//  Copyright © 2020 Dimension. All rights reserved.
//

import Foundation
import CoreData
import Combine

final public class ManagedObjectObserver {
    private init() { }
}

extension ManagedObjectObserver {
    
    public static func observe(context: NSManagedObjectContext) -> AnyPublisher<Changes, Error> {
        
        return NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .tryMap { notification in
                guard let notification = ManagedObjectContextObjectsDidChangeNotification(notification: notification) else {
                    throw Error.notManagedObjectChangeNotification
                }
                
                let changeTypes = ManagedObjectObserver.changeTypes(in: notification)
                return Changes(
                    changeTypes: changeTypes,
                    changeNotification: notification
                )
            }
            .mapError { error -> Error in
                return (error as? Error) ?? .unknown(error)
            }
            .eraseToAnyPublisher()
    }
    
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
    private static func changeTypes(in notification: ManagedObjectContextObjectsDidChangeNotification) -> [ChangeType] {
        var changeTypes: [ChangeType] = []
        
        let deleted = notification.deletedObjects.union(notification.invalidedObjects)
        for object in deleted {
            changeTypes.append(.delete(object))
        }
        
        let updated = notification.updatedObjects.union(notification.refreshedObjects)
        for object in updated {
            changeTypes.append(.update(object))
        }
        
        return changeTypes
    }
    
    private static func changeType(of object: NSManagedObject, in notification: ManagedObjectContextObjectsDidChangeNotification) -> ChangeType? {
        let deleted = notification.deletedObjects.union(notification.invalidedObjects)
        if notification.invalidatedAllObjects || deleted.contains(where: { $0 === object }) {
            return .delete(object)
        }
        
        let updated = notification.updatedObjects.union(notification.refreshedObjects)
        if let object = updated.first(where: { $0 === object }) {
            return .update(object)
        }
        
        return nil
    }
}

extension ManagedObjectObserver {
    public struct Changes {
        public let changeTypes: [ChangeType]
        public let changeNotification: ManagedObjectContextObjectsDidChangeNotification
                
        init(changeTypes: [ManagedObjectObserver.ChangeType], changeNotification: ManagedObjectContextObjectsDidChangeNotification) {
            self.changeTypes = changeTypes
            self.changeNotification = changeNotification
        }
    }
    
    public struct Change {
        public let changeType: ChangeType?
        public let changeNotification: ManagedObjectContextObjectsDidChangeNotification
                
        init(changeType: ManagedObjectObserver.ChangeType?, changeNotification: ManagedObjectContextObjectsDidChangeNotification) {
            self.changeType = changeType
            self.changeNotification = changeNotification
        }
    }
    
    public enum ChangeType {
        case delete(NSManagedObject)
        case update(NSManagedObject)
    }
    
    public enum Error: Swift.Error {
        case unknown(Swift.Error)
        case noManagedObjectContext
        case notManagedObjectChangeNotification
    }
}
