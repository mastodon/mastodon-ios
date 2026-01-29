//
//  APIService.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import AlamofireImage
// import AlamofireNetworkActivityIndicator

@MainActor
public final class APIService {
    
    @MainActor
    public static let shared = { APIService(backgroundContext: PersistenceManager.shared.backgroundManagedObjectContext) }()
    
    public static let callbackURLScheme = "mastodon"
    nonisolated public static let oauthCallbackURL = "mastodon://joinmastodon.org/oauth"

    // internal
    let session: URLSession
    
    public let backgroundManagedObjectContext: NSManagedObjectContext

    // output
    public let error = PassthroughSubject<APIError, Never>()
    
    private init(backgroundContext: NSManagedObjectContext) {
        backgroundManagedObjectContext = backgroundContext
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["User-Agent" : "mastodon-ios/" + appVersion]
        self.session = URLSession(configuration: configuration)

        // setup cache. 10MB RAM + 50MB Disk
        URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
        
        // enable network activity manager for AlamofireImage
        // NetworkActivityIndicatorManager.shared.isEnabled = true
        // NetworkActivityIndicatorManager.shared.startDelay = 0.2
        // NetworkActivityIndicatorManager.shared.completionDelay = 0.5
        
        UIImageView.af.sharedImageDownloader = ImageDownloader(downloadPrioritization: .lifo)
    }
    
    public static func isolatedService() -> APIService {
        let taskContext = PersistenceManager.shared.newTaskContext()
        return APIService(backgroundContext: taskContext)
    }
}

extension APIService {
    public static let onceRequestStatusMaxCount = 100
    public static let onceRequestUserMaxCount = 100
    public static let onceRequestDomainBlocksMaxCount = 100
}

extension APIService {
    public enum Persist { }
    public enum CoreData { }
}
