//
//  APIService+Persist+Status.swift
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
        case user
        case likeList
        case lookUp
    }
    
    static func persistStatus(
        managedObjectContext: NSManagedObjectContext,
        domain: String,
        query: Mastodon.API.Timeline.TimelineQuery?,
        response: Mastodon.Response.Content<[Mastodon.Entity.Status]>,
        persistType: PersistTimelineType,
        requestMastodonUserID: MastodonUser.ID?,        // could be nil when response from public endpoint
        log: OSLog
    ) -> AnyPublisher<Result<Void, Error>, Never> {
        return managedObjectContext.performChanges {
            let statuses = response.value
            os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: persist %{public}ld statuses…", ((#file as NSString).lastPathComponent), #line, #function, statuses.count)
            
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
            os_signpost(.begin, log: log, name: "load statuses & users into cache", signpostID: cacheTaskSignpostID)
            
            // contains reblog
            let statusCache: PersistCache<Status> = {
                let cache = PersistCache<Status>()
                let cacheIDs = PersistCache<Status>.ids(for: statuses)
                let cachedStatuses: [Status] = {
                    let request = Status.sortedFetchRequest
                    let ids = Array(cacheIDs)
                    request.predicate = Status.predicate(domain: domain, ids: ids)
                    request.returnsObjectsAsFaults = false
                    request.relationshipKeyPathsForPrefetching = [#keyPath(Status.reblog)]
                    do {
                        return try managedObjectContext.fetch(request)
                    } catch {
                        assertionFailure(error.localizedDescription)
                        return []
                    }
                }()
                for status in cachedStatuses {
                    cache.dictionary[status.id] = status
                }
                os_signpost(.event, log: log, name: "load status into cache", signpostID: cacheTaskSignpostID, "cached %{public}ld statuses", cachedStatuses.count)
                return cache
            }()
            
            let userCache: PersistCache<MastodonUser> = {
                let cache = PersistCache<MastodonUser>()
                let cacheIDs = PersistCache<MastodonUser>.ids(for: statuses)
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

            os_signpost(.end, log: log, name: "load statuses & users into cache", signpostID: cacheTaskSignpostID)

            // remote timeline merge local timeline record set
            // declare it before persist
            let mergedOldStatusesInTimeline = statusCache.dictionary.values.filter {
                return $0.homeTimelineIndexes?.contains(where: { $0.userID == requestMastodonUserID }) ?? false
            }
            
            let updateDatabaseTaskSignpostID = OSSignpostID(log: log)
            let memoType: PersistMemo<Status, MastodonUser>.MemoType = {
                switch persistType {
                case .home:             return .homeTimeline
                case .public:           return .publicTimeline
                case .user:             return .userTimeline
                case .likeList:         return .likeList
                case .lookUp:           return .lookUp
                }
            }()
            
            var persistMemos: [PersistMemo<Status, MastodonUser>] = []
            os_signpost(.begin, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
            for entity in statuses {
                let processEntityTaskSignpostID = OSSignpostID(log: log)
                os_signpost(.begin, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.id)
                defer {
                    os_signpost(.end, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.id)
                }
                let memo = PersistMemo.createOrMergeStatus(
                    into: managedObjectContext,
                    for: requestMastodonUser,
                    requestMastodonUserID: requestMastodonUserID,
                    domain: domain,
                    entity: entity,
                    memoType: memoType,
                    statusCache: statusCache,
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
                // do not use working records due to anchor status is removable on the remote
                var anchorStatus: Status?
                if let maxID = query.maxID {
                    do {
                        // load anchor status from database
                        let request = Status.sortedFetchRequest
                        request.predicate = Status.predicate(domain: domain, id: maxID)
                        request.returnsObjectsAsFaults = false
                        request.fetchLimit = 1
                        anchorStatus = try managedObjectContext.fetch(request).first
                        if persistType == .home {
                            let timelineIndex = anchorStatus.flatMap { status in
                                status.homeTimelineIndexes?.first(where: { $0.userID == requestMastodonUserID })
                            }
                            timelineIndex?.update(hasMore: false)
                        } else {
                            assertionFailure()
                        }
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
                
                // Task 2: set last status hasMore when fetched statuses not overlap with the timeline in the local database
                let _oldestMemo = persistMemos
                    .sorted(by: { $0.status.createdAt < $1.status.createdAt })
                    .first
                if let oldestMemo = _oldestMemo {
                    if let anchorStatus = anchorStatus {
                        // using anchor. set hasMore when (overlap itself OR no overlap) AND oldest record NOT anchor
                        let isNoOverlap = mergedOldStatusesInTimeline.isEmpty
                        let isOnlyOverlapItself = mergedOldStatusesInTimeline.count == 1 && mergedOldStatusesInTimeline.first?.id == anchorStatus.id
                        let isAnchorEqualOldestRecord = oldestMemo.status.id == anchorStatus.id
                        if (isNoOverlap || isOnlyOverlapItself) && !isAnchorEqualOldestRecord {
                            if persistType == .home {
                                let timelineIndex = oldestMemo.status.homeTimelineIndexes?
                                    .first(where: { $0.userID == requestMastodonUserID })
                                timelineIndex?.update(hasMore: true)
                            } else {
                                assertionFailure()
                            }
                        }
                        
                    } else if mergedOldStatusesInTimeline.isEmpty {
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
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: tweet: insert %{public}ldT(%{public}ldTRQ), merge %{public}ldT(%{public}ldTRQ)", ((#file as NSString).lastPathComponent), #line, #function, newTweetsInTimeLineCount, counting.status.create, mergedOldStatusesInTimeline.count, counting.status.merge)
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
