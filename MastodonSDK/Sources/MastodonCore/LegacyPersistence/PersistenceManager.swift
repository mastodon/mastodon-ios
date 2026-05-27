//
//  PersistenceManager.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 11/15/24.
//
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

@MainActor
public class PersistenceManager {
    public static let shared = { PersistenceManager() }()
    private let coreDataStack: CoreDataStack
    public let mainActorManagedObjectContext: NSManagedObjectContext
    public let backgroundManagedObjectContext: NSManagedObjectContext
    
    private var disposeBag = Set<AnyCancellable>()
    
    private init() {
        let _coreDataStack = CoreDataStack()
        let _managedObjectContext = _coreDataStack.persistentContainer.viewContext
        let _backgroundManagedObjectContext = _coreDataStack.persistentContainer.newBackgroundContext()
        
        coreDataStack = _coreDataStack
        mainActorManagedObjectContext = _managedObjectContext
        backgroundManagedObjectContext = _backgroundManagedObjectContext
        
        backgroundManagedObjectContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: backgroundManagedObjectContext)
            .sink { [weak self] notification in
                guard let self = self else { return }
                self.mainActorManagedObjectContext.perform {
                    self.mainActorManagedObjectContext.mergeChanges(fromContextDidSave: notification)
                }
            }
            .store(in: &disposeBag)
    }
    
    public func newTaskContext() -> NSManagedObjectContext {
        return coreDataStack.newTaskContext()
    }
    
    public func cachedAccount(for authentication: MastodonAuthentication) -> Mastodon.Entity.Account? {
        let account = FileManager
            .default
            .accounts(for: authentication.userIdentifier())
            .first(where: { $0.id == authentication.userID && $0.domain == authentication.domain })
        return account
    }
    
    public func cacheAccount(_ account: Mastodon.Entity.Account, forUserID userID: MastodonUserIdentifier) {
        FileManager.default.store(account: account, forUserID: userID)
    }
    
    public func cached<T: Decodable>(_ cacheType: Persistence) throws -> [T] {
        return try FileManager.default.cached(cacheType)
    }
    
    public func cache<T: Encodable>(_ items: [T], for cacheType: Persistence) {
        FileManager.default.cache(items, for: cacheType)
    }

    public func removeAllCaches(forUser user: UserIdentifier) {
        FileManager.default.invalidate(cache: .accounts(user))
        FileManager.default.invalidate(cache: .groupedNotificationsAll(user))
        FileManager.default.invalidate(cache: .groupedNotificationsAllAccounts(user))
        FileManager.default.invalidate(cache: .groupedNotificationsAllPartialAccounts(user))
        FileManager.default.invalidate(cache: .groupedNotificationsAllStatuses(user))
        FileManager.default.invalidate(cache: .groupedNotificationsMentions(user))
        FileManager.default.invalidate(cache: .groupedNotificationsMentionsAccounts(user))
        FileManager.default.invalidate(cache: .groupedNotificationsMentionsPartialAccounts(user))
        FileManager.default.invalidate(cache: .groupedNotificationsMentionsStatuses(user))
        FileManager.default.invalidate(cache: .homeTimeline(user))
        FileManager.default.invalidate(cache: .searchHistory(user))
        FileManager.default.invalidate(cache: .notificationsAll(user))
    }
}

private extension FileManager {
    static let cacheItemsLimit: Int = 100 // max number of items to cache
    
    func cached<T: Decodable>(_ cacheType: Persistence) throws -> [T] {
        guard let cachesDirectory else { return [] }
        
        let filePath = cacheType.filepath(baseURL: cachesDirectory)
        
        guard let data = try? Data(contentsOf: filePath) else { return [] }
        
        do {
            let items = try JSONDecoder().decode([T].self, from: data)
            
            return items
        } catch {
            return []
        }
    }
    
    func cache<T: Encodable>(_ items: [T], for cacheType: Persistence) {
        guard let cachesDirectory else { return }
        
        let processableItems: [T]
        if items.count > Self.cacheItemsLimit {
            processableItems = items.dropLast(items.count - Self.cacheItemsLimit)
        } else {
            processableItems = items
        }
        
        do {
            let data = try JSONEncoder().encode(processableItems)
            
            let filePath = cacheType.filepath(baseURL: cachesDirectory)
            try data.write(to: filePath)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func invalidate(cache: Persistence) {
        guard let cachesDirectory else { return }
        
        let filePath = cache.filepath(baseURL: cachesDirectory)
        
        try? removeItem(at: filePath)
    }
}

private extension FileManager {
    func store(account: Mastodon.Entity.Account, forUserID userID: UserIdentifier) {
        var accounts = accounts(for: userID)
        
        if let index = accounts.firstIndex(of: account) {
            accounts.remove(at: index)
        }
        
        accounts.append(account)
        
        storeJSON(accounts, userID: userID)
    }
    
    func accounts(for userId: UserIdentifier) -> [Mastodon.Entity.Account] {
        guard let sharedDirectory else { assert(false); return [] }
        
        let accountPath = Persistence.accounts(userId).filepath(baseURL: sharedDirectory)
        
        guard let data = try? Data(contentsOf: accountPath) else { return [] }
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        do {
            let accounts = try jsonDecoder.decode([Mastodon.Entity.Account].self, from: data)
            assert(accounts.count > 0)
            return accounts
        } catch {
            return []
        }
        
    }
}

private extension FileManager {
    private func storeJSON(_ encodable: Encodable, userID: UserIdentifier) {
        guard let sharedDirectory else { return }
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        do {
            let data = try jsonEncoder.encode(encodable)
            
            let accountsPath = Persistence.accounts( userID).filepath(baseURL: sharedDirectory)
            try data.write(to: accountsPath)
        } catch {
            debugPrint(error.localizedDescription)
        }
        
    }
    
}
