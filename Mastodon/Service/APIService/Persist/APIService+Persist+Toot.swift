//
//  APIService+Persist+Toot.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import os.log
import func QuartzCore.CACurrentMediaTime
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService.Persist {
    
    enum PersistTimelineType {
        case `public`
        case home
        case likeList
        case lookUp
    }
    
    static func persistToots(
        managedObjectContext: NSManagedObjectContext,
        domain: String,
        query: Mastodon.API.Timeline.TimelineQuery?,
        response: Mastodon.Response.Content<[Mastodon.Entity.Status]>,
        persistType: PersistTimelineType,
        requestMastodonUserID: MastodonUser.ID?,        // could be nil when response from public endpoint
        log: OSLog
    ) -> AnyPublisher<Result<Void, Error>, Never> {
        return managedObjectContext.performChanges {
            let toots = response.value
            os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: persist %{public}ld toots…", ((#file as NSString).lastPathComponent), #line, #function, toots.count)
            
            let contextTaskSignpostID = OSSignpostID(log: log)
            let start = CACurrentMediaTime()
            os_signpost(.begin, log: log, name: #function, signpostID: contextTaskSignpostID)
            defer {
                os_signpost(.end, log: .api, name: #function, signpostID: contextTaskSignpostID)
                let end = CACurrentMediaTime()
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: persist cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
            }

            // load request mastodon user
            let requestMastodonUser: MastodonUser? = {
                guard let requestMastodonUserID = requestMastodonUserID else { return nil }
                let request = MastodonUser.sortedFetchRequest
                request.predicate = MastodonUser.predicate(domain: domain, id: requestMastodonUserID)
                request.fetchLimit = 1
                request.returnsObjectsAsFaults = false
                do {
                    return try managedObjectContext.fetch(request).first
                } catch {
                    assertionFailure(error.localizedDescription)
                    return nil
                }
            }()
            
            // load working set into context to avoid cache miss
            let cacheTaskSignpostID = OSSignpostID(log: log)
            os_signpost(.begin, log: log, name: "load toots & users into cache", signpostID: cacheTaskSignpostID)
            
            // contains reblog
            let tootCache: PersistCache<Toot> = {
                let cache = PersistCache<Toot>()
                let cacheIDs = PersistCache<Toot>.ids(for: toots)
                let cachedToots: [Toot] = {
                    let request = Toot.sortedFetchRequest
                    let ids = Array(cacheIDs)
                    request.predicate = Toot.predicate(domain: domain, ids: ids)
                    request.returnsObjectsAsFaults = false
                    request.relationshipKeyPathsForPrefetching = [#keyPath(Toot.reblog)]
                    do {
                        return try managedObjectContext.fetch(request)
                    } catch {
                        assertionFailure(error.localizedDescription)
                        return []
                    }
                }()
                for toot in cachedToots {
                    cache.dictionary[toot.id] = toot
                }
                os_signpost(.event, log: log, name: "load toot into cache", signpostID: cacheTaskSignpostID, "cached %{public}ld toots", cachedToots.count)
                return cache
            }()
            
            let userCache: PersistCache<MastodonUser> = {
                let cache = PersistCache<MastodonUser>()
                let cacheIDs = PersistCache<MastodonUser>.ids(for: toots)
                let cachedMastodonUsers: [MastodonUser] = {
                    let request = MastodonUser.sortedFetchRequest
                    let ids = Array(cacheIDs)
                    request.predicate = MastodonUser.predicate(domain: domain, ids: ids)
                    //request.returnsObjectsAsFaults = false
                    do {
                        return try managedObjectContext.fetch(request)
                    } catch {
                        assertionFailure(error.localizedDescription)
                        return []
                    }
                }()
                for mastodonuser in cachedMastodonUsers {
                    cache.dictionary[mastodonuser.id] = mastodonuser
                }
                os_signpost(.event, log: log, name: "load user into cache", signpostID: cacheTaskSignpostID, "cached %{public}ld users", cachedMastodonUsers.count)
                return cache
            }()

            os_signpost(.end, log: log, name: "load toots & users into cache", signpostID: cacheTaskSignpostID)

            // remote timeline merge local timeline record set
            // declare it before persist
            let mergedOldTootsInTimeline = tootCache.dictionary.values.filter {
                return $0.homeTimelineIndexes?.contains(where: { $0.userID == requestMastodonUserID }) ?? false
            }
            
            let updateDatabaseTaskSignpostID = OSSignpostID(log: log)
            let memoType: PersistMemo<Toot, MastodonUser>.MemoType = {
                switch persistType {
                case .home:             return .homeTimeline
                case .public:           return .publicTimeline
                case .likeList:         return .likeList
                case .lookUp:           return .lookUp
                }
            }()
            
            var persistMemos: [PersistMemo<Toot, MastodonUser>] = []
            os_signpost(.begin, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
            for entity in toots {
                let processEntityTaskSignpostID = OSSignpostID(log: log)
                os_signpost(.begin, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.id)
                defer {
                    os_signpost(.end, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.id)
                }
                let memo = PersistMemo.createOrMergeToot(
                    into: managedObjectContext,
                    for: requestMastodonUser,
                    requestMastodonUserID: requestMastodonUserID,
                    domain: domain,
                    entity: entity,
                    memoType: memoType,
                    tootCache: tootCache,
                    userCache: userCache,
                    networkDate: response.networkDate,
                    log: log
                )
                persistMemos.append(memo)
            }   // end for…
            os_signpost(.end, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
            
            // home timeline tasks
            switch persistType {
            case .home:
                guard let query = query,
                      let requestMastodonUserID = requestMastodonUserID else {
                    assertionFailure()
                    return
                }
                // Task 1: update anchor hasMore
                // update maxID anchor hasMore attribute when fetching on home timeline
                // do not use working records due to anchor toot is removable on the remote
                var anchorToot: Toot?
                if let maxID = query.maxID {
                    do {
                        // load anchor toot from database
                        let request = Toot.sortedFetchRequest
                        request.predicate = Toot.predicate(domain: domain, id: maxID)
                        request.returnsObjectsAsFaults = false
                        request.fetchLimit = 1
                        anchorToot = try managedObjectContext.fetch(request).first
                        if persistType == .home {
                            let timelineIndex = anchorToot.flatMap { toot in
                                toot.homeTimelineIndexes?.first(where: { $0.userID == requestMastodonUserID })
                            }
                            timelineIndex?.update(hasMore: false)
                        } else {
                            assertionFailure()
                        }
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
                
                // Task 2: set last toot hasMore when fetched toots not overlap with the timeline in the local database
                let _oldestMemo = persistMemos
                    .sorted(by: { $0.status.createdAt < $1.status.createdAt })
                    .first
                if let oldestMemo = _oldestMemo {
                    if let anchorToot = anchorToot {
                        // using anchor. set hasMore when (overlap itself OR no overlap) AND oldest record NOT anchor
                        let isNoOverlap = mergedOldTootsInTimeline.isEmpty
                        let isOnlyOverlapItself = mergedOldTootsInTimeline.count == 1 && mergedOldTootsInTimeline.first?.id == anchorToot.id
                        let isAnchorEqualOldestRecord = oldestMemo.status.id == anchorToot.id
                        if (isNoOverlap || isOnlyOverlapItself) && !isAnchorEqualOldestRecord {
                            if persistType == .home {
                                let timelineIndex = oldestMemo.status.homeTimelineIndexes?
                                    .first(where: { $0.userID == requestMastodonUserID })
                                timelineIndex?.update(hasMore: true)
                            } else {
                                assertionFailure()
                            }
                        }
                        
                    } else if mergedOldTootsInTimeline.isEmpty {
                        // no anchor. set hasMore when no overlap
                        if persistType == .home {
                            let timelineIndex = oldestMemo.status.homeTimelineIndexes?
                                .first(where: { $0.userID == requestMastodonUserID })
                            timelineIndex?.update(hasMore: true)
                        }
                    }
                } else {
                    // empty working record. mark anchor hasMore in the task 1
                }
            default:
                break
            }
            
            // print working record tree map
            #if DEBUG
            DispatchQueue.global(qos: .utility).async {
                let logs = persistMemos
                    .map { record in record.log() }
                    .joined(separator: "\n")
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: working status: \n%s", ((#file as NSString).lastPathComponent), #line, #function, logs)
                let counting = persistMemos
                    .map { record in record.count() }
                    .reduce(into: PersistMemo.Counting(), { result, next in result = result + next })
                let newTweetsInTimeLineCount = persistMemos.reduce(0, { result, next in
                    return next.statusProcessType == .create ? result + 1 : result
                })
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: tweet: insert %{public}ldT(%{public}ldTRQ), merge %{public}ldT(%{public}ldTRQ)", ((#file as NSString).lastPathComponent), #line, #function, newTweetsInTimeLineCount, counting.status.create, mergedOldTootsInTimeline.count, counting.status.merge)
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: twitter user: insert %{public}ld, merge %{public}ld", ((#file as NSString).lastPathComponent), #line, #function, counting.user.create, counting.user.merge)
            }
            #endif
        }
        .eraseToAnyPublisher()
        .handleEvents(receiveOutput: { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                #if DEBUG
                debugPrint(error)
                #endif
                assertionFailure(error.localizedDescription)
            }
        })
        .eraseToAnyPublisher()
    }
}
