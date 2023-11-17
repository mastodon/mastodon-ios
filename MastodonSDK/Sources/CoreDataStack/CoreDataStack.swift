//
//  CoreDataStack.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2021-1-27.
//

import os
import Foundation
import Combine
@_exported import CoreData
import MastodonCommon

public final class CoreDataStack {
    
    private(set) var storeDescriptions: [NSPersistentStoreDescription]
    public let didFinishLoad = CurrentValueSubject<Bool, Never>(false)
    
    init(persistentStoreDescriptions storeDescriptions: [NSPersistentStoreDescription]) {
        self.storeDescriptions = storeDescriptions
    }
    
    public convenience init(databaseName: String = "shared", isInMemory: Bool = false) {
        let storeURL = URL.storeURL(for: AppName.groupID, databaseName: databaseName)
        let storeDescription: NSPersistentStoreDescription
        if isInMemory {
            storeDescription = NSPersistentStoreDescription(url: URL(string: "file:///dev/null")!)  /// in-memory store with all features in favor of NSInMemoryStoreType
        } else {
            storeDescription = NSPersistentStoreDescription(url: storeURL)
        }
        self.init(persistentStoreDescriptions: [storeDescription])
    }
    
    public private(set) lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = CoreDataStack.persistentContainer()
        CoreDataStack.configure(persistentContainer: container, storeDescriptions: storeDescriptions)
        CoreDataStack.load(persistentContainer: container) { [weak self] in
            guard let self = self else { return }
            self.didFinishLoad.value = true
        }

        return container
    }()

    static func persistentContainer() -> NSPersistentContainer {
        let bundles = [Bundle.module]   // .module required for package in the SwiftPM
        guard let managedObjectModel = NSManagedObjectModel.mergedModel(from: bundles) else {
            fatalError("cannot locate bundles")
        }
        
        let container = NSPersistentContainer(name: "CoreDataStack", managedObjectModel: managedObjectModel)
        return container
    }
    
    static func configure(persistentContainer container: NSPersistentContainer, storeDescriptions: [NSPersistentStoreDescription]) {
        container.persistentStoreDescriptions = storeDescriptions
    }
    
    static func load(persistentContainer container: NSPersistentContainer, callback: @escaping () -> Void) {
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                if let reason = error.userInfo["reason"] as? String,
                   (reason == "Can't find mapping model for migration" || reason == "Persistent store migration failed, missing mapping model.")  {
                    if let storeDescription = container.persistentStoreDescriptions.first, let url = storeDescription.url {
                        try? container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
                    } else {
                        assertionFailure()
                    }
                }

                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            // it's looks like the remote notification only trigger when app enter and leave background
            container.viewContext.automaticallyMergesChangesFromParent = true

            callback()
        })
    }
    
}

extension CoreDataStack {
    public func newTaskContext() -> NSManagedObjectContext {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        taskContext.undoManager = nil
        return taskContext
    }
}

public extension CoreDataStack {
    func tearDown() {
        let oldStoreURL = persistentContainer.persistentStoreCoordinator.url(for: persistentContainer.persistentStoreCoordinator.persistentStores.first!)
        try! persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: oldStoreURL, ofType: NSSQLiteStoreType, options: nil)
    }
    
    func rebuild() {
        tearDown()
        
        CoreDataStack.load(persistentContainer: persistentContainer) { [weak self] in
            guard let self = self else { return }
            self.didFinishLoad.value = true
        }
    }
}
