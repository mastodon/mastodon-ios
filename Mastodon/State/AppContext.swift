//
//  AppContext.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

class AppContext: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    @Published var viewStateStore = ViewStateStore()
        
    let coreDataStack: CoreDataStack
    let managedObjectContext: NSManagedObjectContext
    let backgroundManagedObjectContext: NSManagedObjectContext
    
    let apiService: APIService
    let authenticationService: AuthenticationService
    
    let documentStore: DocumentStore
    private var documentStoreSubscription: AnyCancellable!
    
    let videoPlaybackService = VideoPlaybackService()
    let audioPlaybackService = AudioPlaybackService()
    
    let overrideTraitCollection = CurrentValueSubject<UITraitCollection?, Never>(nil)

    init() {
        let _coreDataStack = CoreDataStack()
        let _managedObjectContext = _coreDataStack.persistentContainer.viewContext
        let _backgroundManagedObjectContext = _coreDataStack.persistentContainer.newBackgroundContext()
        coreDataStack = _coreDataStack
        managedObjectContext = _managedObjectContext
        backgroundManagedObjectContext = _backgroundManagedObjectContext
        
        let _apiService = APIService(backgroundManagedObjectContext: _backgroundManagedObjectContext)
        apiService = _apiService
        
        authenticationService = AuthenticationService(
            managedObjectContext: _managedObjectContext,
            backgroundManagedObjectContext: _backgroundManagedObjectContext,
            apiService: _apiService
        )
        
        documentStore = DocumentStore()
        documentStoreSubscription = documentStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                self.objectWillChange.send()
            }
        
        backgroundManagedObjectContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: backgroundManagedObjectContext)
            .sink { [weak self] notification in
                guard let self = self else { return }
                self.managedObjectContext.perform {
                    self.managedObjectContext.mergeChanges(fromContextDidSave: notification)
                }
            }
            .store(in: &disposeBag)
    }
    
}
