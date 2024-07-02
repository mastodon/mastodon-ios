//
//  AppContext.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import UIKit
import SwiftUI
import Combine
import CoreData
import CoreDataStack
import AlamofireImage

public class AppContext: ObservableObject {
    
    public var disposeBag = Set<AnyCancellable>()
    
    public let coreDataStack: CoreDataStack
    public let managedObjectContext: NSManagedObjectContext
    public let backgroundManagedObjectContext: NSManagedObjectContext
    
    public let apiService: APIService
    public let authenticationService: AuthenticationService
    public let emojiService: EmojiService

    public let publisherService: PublisherService
    public let notificationService: NotificationService
    public let settingService: SettingService
    public let instanceService: InstanceService

    public let blockDomainService: BlockDomainService
    public let statusFilterService: StatusFilterService
    public let photoLibraryService = PhotoLibraryService()

    public let placeholderImageCacheService = PlaceholderImageCacheService()
    public let blurhashImageCacheService = BlurhashImageCacheService.shared

    public let documentStore: DocumentStore
    private var documentStoreSubscription: AnyCancellable!
    
    let overrideTraitCollection = CurrentValueSubject<UITraitCollection?, Never>(nil)
    let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()
    
    public init() {

        let authProvider = AuthenticationServiceProvider.shared
        let _coreDataStack = CoreDataStack()
        if authProvider.authenticationMigrationRequired {
            authProvider.migrateLegacyAuthentications(
                in: _coreDataStack.persistentContainer.viewContext
            )
        }

        let _managedObjectContext = _coreDataStack.persistentContainer.viewContext
        let _backgroundManagedObjectContext = _coreDataStack.persistentContainer.newBackgroundContext()

        coreDataStack = _coreDataStack
        managedObjectContext = _managedObjectContext
        backgroundManagedObjectContext = _backgroundManagedObjectContext
        
        let _apiService = APIService(backgroundManagedObjectContext: _backgroundManagedObjectContext)
        apiService = _apiService
        
        let _authenticationService = AuthenticationService(
            managedObjectContext: _managedObjectContext,
            backgroundManagedObjectContext: _backgroundManagedObjectContext,
            apiService: _apiService
        )
        authenticationService = _authenticationService
        
        emojiService = EmojiService(
            apiService: apiService,
            authenticationService: _authenticationService
        )
        
        publisherService = .init(apiService: _apiService)
        
        let _notificationService = NotificationService(
            apiService: _apiService,
            authenticationService: _authenticationService
        )
        notificationService = _notificationService
        
        settingService = SettingService(
            apiService: _apiService,
            authenticationService: _authenticationService,
            notificationService: _notificationService
        )
        
        instanceService = InstanceService(
            apiService: _apiService,
            authenticationService: _authenticationService
        )
        
        blockDomainService = BlockDomainService(
            backgroundManagedObjectContext: _backgroundManagedObjectContext,
            authenticationService: _authenticationService
        )

        statusFilterService = StatusFilterService(
            apiService: _apiService,
            authenticationService: _authenticationService
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

extension AppContext {
    
    public typealias ByteCount = Int
    
    public static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        return formatter
    }()
    
    public func purgeCache() {
        ImageDownloader.defaultURLCache().removeAllCachedResponses()

        let fileManager = FileManager.default
        let temporaryDirectoryURL = fileManager.temporaryDirectory
        let fileKeys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]

        if let directoryEnumerator = fileManager.enumerator(
            at: temporaryDirectoryURL,
            includingPropertiesForKeys: fileKeys,
            options: .skipsHiddenFiles) {
            for case let fileURL as URL in directoryEnumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(fileKeys)),
                      resourceValues.isDirectory == false else {
                    continue
                }

                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    // In Bytes
    public func currentDiskUsage() -> Int {
        let alamoFireDiskBytes = ImageDownloader.defaultURLCache().currentDiskUsage

        var tempFilesDiskBytes = 0
        let fileManager = FileManager.default
        let temporaryDirectoryURL = fileManager.temporaryDirectory
        let fileKeys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]

        if let directoryEnumerator = fileManager.enumerator(
            at: temporaryDirectoryURL,
            includingPropertiesForKeys: fileKeys,
            options: .skipsHiddenFiles) {
            for case let fileURL as URL in directoryEnumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(fileKeys)),
                      resourceValues.isDirectory == false else {
                    continue
                }

                tempFilesDiskBytes += resourceValues.fileSize ?? 0
            }
        }

        return alamoFireDiskBytes + tempFilesDiskBytes
    }
}
