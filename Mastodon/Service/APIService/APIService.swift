//
//  APIService.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import AlamofireImage
import AlamofireNetworkActivityIndicator

final class APIService {
        
    var disposeBag = Set<AnyCancellable>()
    
    // internal
    let session: URLSession

    
    // input
    let backgroundManagedObjectContext: NSManagedObjectContext

    // output
    let error = PassthroughSubject<APIError, Never>()
    
    init(backgroundManagedObjectContext: NSManagedObjectContext) {
        self.backgroundManagedObjectContext = backgroundManagedObjectContext
        self.session = URLSession(configuration: .default)
        
        // setup cache. 10MB RAM + 50MB Disk
        URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
        
        // enable network activity manager for AlamofireImage
        NetworkActivityIndicatorManager.shared.isEnabled = true
        NetworkActivityIndicatorManager.shared.startDelay = 0.2
        NetworkActivityIndicatorManager.shared.completionDelay = 0.5
    }
    
}

extension APIService {
    public static let onceRequestTootMaxCount = 100
    public static let onceRequestUserMaxCount = 100
}

extension APIService {
    public enum Persist { }
    public enum CoreData { }
}
