// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Combine
import Foundation
import MastodonCore
import MastodonSDK

@MainActor
public protocol CacheableFeed {
    var hasResults: Bool { get }
}

public enum MastodonFeedLoaderError: Error {
    case requestNotImplemented
}

/// Implementations of `MastodonFeedCacheManager` are expected to initialize their current results from the cache, merge newly fetched items with previously fetched upon request, and write the updated results to the cache when requested. Separating the published type (which must be published in an array) from the cached type allows the cache manager to save something more complex than a simple array. For instance, the accounts associated with a list of posts might be stored separately from the posts themselves.
@MainActor
protocol MastodonFeedCacheManager<CachedType> {
    associatedtype CachedType

    func currentResults() -> CachedType?
    var currentLastReadMarker: LastReadMarkers.MarkerPosition? { get }
    var mostRecentlyFetchedResults: CachedType? { get }
    func updateByInserting(newlyFetched: CachedType, at insertionPoint: MastodonFeedLoaderRequest.InsertLocation)
    func didFetchMarkers(_ updatedMarkers: Mastodon.Entity.Marker)
    func updateToNewerMarker(_ newMarker: LastReadMarkers.MarkerPosition, enforceForwardProgress: Bool)
    func commitToCache() async
    func clearCache() async
}

public struct MastodonFeedLoaderResult<ResultType> {
    let allRecords: [ResultType]
    let canLoadOlder: Bool
}

public enum MastodonFeedLoaderRequest: Equatable {
    case older
    case newer
    case reload
    case newerThan(String)
    case olderThan(String)
    
    var resultsInsertionPoint: InsertLocation {
        switch self {
        case .older:
            return .end
        case .newer:
            return .start
        case .reload:
            return .replace
        case .newerThan(let id):
            return .asNewerThan(id)
        case .olderThan(let id):
            return .asOlderThan(id)
        }
    }
    enum InsertLocation {
        case start
        case end
        case replace
        case asNewerThan(String)
        case asOlderThan(String)
    }
}

/// Collects the common functionality of fetching paginated feeds, filtering and merging their contents, tracking their last read markers, and optionally caching the results locally.
/// Consumers subscribe to the `records` and optionally the `currentError` publishers to display the feed. The consumer is also responsible for requesting loads of additional items in the feed, requesting cache updates, and triggering updates of the last read marker. Begin by calling `doFirstLoad()` on the desired subclass of `MastodonFeedLoader`, which will request the (cached) `currentResults` from the cache manager, fetch the last read markers from the server, and request a load of newer items. Consumers should not interact with the `MastodonFeedCacheManager` directly.
/// Subclasses specify their published type (the `MastodonFeedLoaderResult` published in the feed loader’s records will contain an array of this type, as well as a flag indicating whether there may be older records available to fetch) and the cached type. You will also have to provide an implementation of the `MastodonFeedCacheManager` protocol that works with the specified cached type.
/// Subclasses must override `fetchResults(for request: MastodonFeedLoaderRequest)` (to connect to the correct API endpoint) and `filteredResults(fromCachedType: CachedType)`  (to apply the user’s filters appropriately to the context).
/// The provided implementation handles handles removing duplicate records from the feed, fetching the user's filters and updating when they are received, and determining whether there are additional items left to fetch.
@MainActor
public class MastodonFeedLoader<PublishedType: Identifiable, CachedType: CacheableFeed> where PublishedType: Sendable {
    private var activeFilterBoxSubscription: AnyCancellable?
    private var loadRequestQueue = [MastodonFeedLoaderRequest]()
    let cacheManager: (any MastodonFeedCacheManager<CachedType>)
    
    @Published private(set) var records = MastodonFeedLoaderResult<PublishedType>(
        allRecords: [], canLoadOlder: true)
    @Published private(set) var currentError: Error? = nil
    
    init(_ cacheManager: (any MastodonFeedCacheManager<CachedType>)) {
        self.cacheManager = cacheManager
        
        activeFilterBoxSubscription = StatusFilterService.shared
            .$activeFilterBox
            .sink { [weak self] _ in
                guard let self else { return }
                if let currentResults = cacheManager.currentResults(), currentResults.hasResults {
                    let refiltered = self.filteredResults(fromCachedType: currentResults)
                    self.replaceRecords(refiltered, canLoadOlder: records.canLoadOlder)
                }
            }
    }
    
    private var isFetching: Bool = false {
        didSet {
            if !isFetching, let waitingRequest = nextRequestThatCanBeLoadedNow() {
                Task {
                    do {
                        try await load(waitingRequest)
                        currentError = nil
                    } catch {
                        currentError = error
                    }
                }
            }
        }
    }
    
    private func nextRequestThatCanBeLoadedNow() -> MastodonFeedLoaderRequest? {
        guard !isFetching else { return nil }
        guard !loadRequestQueue.isEmpty else { return nil }
        let nextRequest = loadRequestQueue.removeFirst()
        isFetching = true
        return nextRequest
    }
    
    func setRecords(_ records: MastodonFeedLoaderResult<PublishedType>) {
        self.records = records
    }
    
    // MARK: Subclasses Must Override
    func fetchResults(for request: MastodonFeedLoaderRequest) async throws -> CachedType {
        fatalError("Subclasses must override fetchResults(for:)")
    }
    func filteredResults(fromCachedType: CachedType) -> [PublishedType] {
        fatalError("Subclasses must override publishedType(fromCachedType:)")
    }
}

extension MastodonFeedLoader {
    public func doFirstLoad() {
        Task {
            do {
                try loadCached()
            } catch {
            }
            do {
                if let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value {
                    let markers = try await APIService.shared.lastReadMarkers(authenticationBox: authBox)
                    cacheManager.didFetchMarkers(markers)
                }
            } catch {
            }
            requestLoad(.reload)
        }
    }
    
    /// Performing a load request calls the subclass’s implementation of `fetchResults(for:﻿)`, then calls the cache manager‘s `updateCacheByInserting(newlyFetchedResults:at:`). The updated `currentResults` from the cache manager are then run through the subclass’s `filteredResults(fromCachedType:﻿)` before being published.
    public func requestLoad(_ request: MastodonFeedLoaderRequest) {
        if !loadRequestQueue.contains(request) {
            loadRequestQueue.append(request)
        }
        if let nextDoableRequest = nextRequestThatCanBeLoadedNow() {
            Task {
                do {
                    try await load(nextDoableRequest)
                    currentError = nil
                } catch {
                    currentError = error
                }
            }
        }
    }
    
    /// Use only with pull to refresh, in order to properly update the progress spinner.
    public var permissionToLoadImmediately: Bool {
        if isFetching {
            return false
        } else {
            isFetching = true
            return true
        }
    }
    /// Use only with pull to refresh, in order to properly update the progress spinner.
    public func loadImmediately(_ request: MastodonFeedLoaderRequest) async {
        guard isFetching else { assertionFailure("request permissionToLoadImmediately before calling loadImmediately"); return }
        do {
            try await load(request)
            currentError = nil
        } catch {
            currentError = error
        }
    }
    
    func load(_ request: MastodonFeedLoaderRequest) async throws
    {
        defer { isFetching = false }
        let unfiltered = try await fetchResults(for: request)
        updateAfterInserting(newlyFetchedResults: unfiltered, at: request.resultsInsertionPoint)
    }
    
    func updateAfterInserting(newlyFetchedResults: CachedType, at insertionPoint: MastodonFeedLoaderRequest.InsertLocation) {
        updateCacheByInserting(newlyFetchedResults: newlyFetchedResults, at: insertionPoint)
        
        let currentResults = cacheManager.currentResults() ?? newlyFetchedResults
        let filtered = filteredResults(fromCachedType: currentResults)
        
        let canLoadOlder: Bool? = {
            switch insertionPoint {
            case .start:
                return nil
            case .asOlderThan, .asNewerThan:
                return records.canLoadOlder
            case .end:
                return nil
            case .replace:
                return filtered.count > 20 // We expect to receive batches of up to 40 items from the server. Setting this threshold gives us enough items to keep the loading indicator off screen, so that when it does appear we can attempt to load older items and if we receive nothing, then remove the loading indicator. Otherwise, if we always assume that more could be loaded but we start off with so few items that the loading indicator is already on screen, then there's no way to get rid of it.
            }
        }()
        replaceRecords(filtered, canLoadOlder: canLoadOlder)
        currentError = nil
    }
    
    private func noMoreResultsToFetch() {
        if records.canLoadOlder {
            setRecords(MastodonFeedLoaderResult(allRecords: records.allRecords, canLoadOlder: false))
        }
    }
    
    private func replaceRecords(_ filtered: [PublishedType], canLoadOlder: Bool? = nil) {
        let actuallyCanLoadOlder = {
            if let newLast = filtered.last?.id, let oldLast = records.allRecords.last?.id {
                return canLoadOlder ?? (newLast != oldLast)
            } else if filtered.isEmpty && records.allRecords.isEmpty {
                return canLoadOlder ?? false
            } else {
                return canLoadOlder ?? true
            }
        }()
        
        setRecords(MastodonFeedLoaderResult(allRecords: checkForDuplicates(filtered), canLoadOlder: actuallyCanLoadOlder))
    }
    
    private func checkForDuplicates(_ items: [PublishedType]) -> [PublishedType] {
        var added = Set<PublishedType.ID>()
        var deduped = [PublishedType]()
        for item in items {
            let id = item.id
            if added.contains(id) {
                continue
            } else {
                deduped.append(item)
                added.insert(id)
            }
        }
        return deduped
    }
}

extension MastodonFeedLoader {
    public func clearCache() async {
        await cacheManager.clearCache()
    }
    
    public func commitToCache() async {
        await cacheManager.commitToCache()
    }
    
    public func updateCachedResults(_ updater: (CachedType)->()) {
        guard let cached = cacheManager.currentResults() else { return }
        updater(cached)
        Task {
            await commitToCache()
        }
    }
    
    public func transformCachedResults(_ updater: (CachedType)->(CachedType)) {
        guard let cached = cacheManager.currentResults() else { return }
        let updatedCache = updater(cached)
        updateAfterInserting(newlyFetchedResults: updatedCache, at: .replace)
    }
    
    private func loadCached() throws {
        guard !isFetching else { return }
        isFetching = true
        defer {
            isFetching = false
        }
        if let currentResults = cacheManager.currentResults() {
            replaceRecords(filteredResults(fromCachedType: currentResults), canLoadOlder: true)
        }
    }

    private func updateCacheByInserting(newlyFetchedResults: CachedType,
                                        at insertionPoint: MastodonFeedLoaderRequest.InsertLocation) {
        switch insertionPoint {
        case .start, .asNewerThan, .asOlderThan:
            guard newlyFetchedResults.hasResults else { return }
        case .replace:
            break
        case .end:
            guard newlyFetchedResults.hasResults else {
                noMoreResultsToFetch()
                return
            }
        }
        cacheManager.updateByInserting(newlyFetched: newlyFetchedResults, at: insertionPoint)
    }
}

extension MastodonFeedLoader {
    var lastReadMarker: LastReadMarkers.MarkerPosition? {
        return cacheManager.currentLastReadMarker
    }
    
    public func markAsRead(_ identifier: String) {
        cacheManager.updateToNewerMarker(.local(lastReadID: identifier), enforceForwardProgress: true)
    }
    
    public func isUnread(_ identifier: String) -> Bool {
        if let lastRead = cacheManager.currentLastReadMarker?.lastReadID {
            return LastReadMarkers.id(lastRead, isOlderThan: identifier)
        } else {
            return false
        }
    }
    
    public func lastRead() -> String? {
        return cacheManager.currentLastReadMarker?.lastReadID
    }
}
