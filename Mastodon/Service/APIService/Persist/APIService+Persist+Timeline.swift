//
//  APIService+Persist+Timeline.swift
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
    }
    
    static func persistTimeline(
        managedObjectContext: NSManagedObjectContext,
        domain: String,
        query: Mastodon.API.Timeline.TimelineQuery,
        response: Mastodon.Response.Content<[Mastodon.Entity.Status]>,
        persistType: PersistTimelineType,
        requestMastodonUserID: MastodonUser.ID?,        // could be nil when response from public endpoint
        log: OSLog
    ) -> AnyPublisher<Result<Void, Error>, Never> {
        let toots = response.value
        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: persist %{public}ld toots…", ((#file as NSString).lastPathComponent), #line, #function, toots.count)

        return managedObjectContext.performChanges {
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
            os_signpost(.begin, log: log, name: "load toots into cache", signpostID: cacheTaskSignpostID)
            let workingIDRecord = APIService.Persist.WorkingIDRecord.workingID(entities: toots)
            
            // contains toots and reblogs
            let _tootCache: [Toot] = {
                let request = Toot.sortedFetchRequest
                let idSet = workingIDRecord.statusIDSet
                    .union(workingIDRecord.reblogIDSet)
                let ids = Array(idSet)
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
            os_signpost(.event, log: log, name: "load toots into cache", signpostID: cacheTaskSignpostID, "cached %{public}ld toots", _tootCache.count)
            os_signpost(.end, log: log, name: "load toots into cache", signpostID: cacheTaskSignpostID)
            
            // remote timeline merge local timeline record set
            // declare it before do working
            let mergedOldTootsInTimeline = _tootCache.filter {
                return $0.homeTimelineIndexes?.contains(where: { $0.userID == requestMastodonUserID }) ?? false
            }
            
            let updateDatabaseTaskSignpostID = OSSignpostID(log: log)
            let recordType: WorkingRecord.RecordType = {
                switch persistType {
                case .public:   return .publicTimeline
                case .home:     return .homeTimeline
                case .likeList: return .favoriteTimeline
                }
            }()

            var workingRecords: [WorkingRecord] = []
            os_signpost(.begin, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
            for entity in toots {
                let processEntityTaskSignpostID = OSSignpostID(log: log)
                os_signpost(.begin, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.id)
                defer {
                    os_signpost(.end, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.id)
                }
                let record = WorkingRecord.createOrMergeToot(
                    into: managedObjectContext,
                    for: requestMastodonUser,
                    domain: domain,
                    entity: entity,
                    recordType: recordType,
                    networkDate: response.networkDate,
                    log: log
                )
                workingRecords.append(record)
            }   // end for…
            os_signpost(.end, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
            
            // home & mention timeline tasks
            switch persistType {
            case .home:
                // Task 1: update anchor hasMore
                // update maxID anchor hasMore attribute when fetching on timeline
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
                let _oldestRecord = workingRecords
                    .sorted(by: { $0.status.createdAt < $1.status.createdAt })
                    .first
                if let oldestRecord = _oldestRecord {
                    if let anchorToot = anchorToot {
                        // using anchor. set hasMore when (overlap itself OR no overlap) AND oldest record NOT anchor
                        let isNoOverlap = mergedOldTootsInTimeline.isEmpty
                        let isOnlyOverlapItself = mergedOldTootsInTimeline.count == 1 && mergedOldTootsInTimeline.first?.id == anchorToot.id
                        let isAnchorEqualOldestRecord = oldestRecord.status.id == anchorToot.id
                        if (isNoOverlap || isOnlyOverlapItself) && !isAnchorEqualOldestRecord {
                            if persistType == .home {
                                let timelineIndex = oldestRecord.status.homeTimelineIndexes?
                                    .first(where: { $0.userID == requestMastodonUserID })
                                timelineIndex?.update(hasMore: true)
                            } else {
                                assertionFailure()
                            }
                        }
                        
                    } else if mergedOldTootsInTimeline.isEmpty {
                        // no anchor. set hasMore when no overlap
                        if persistType == .home {
                            let timelineIndex = oldestRecord.status.homeTimelineIndexes?
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
                let logs = workingRecords
                    .map { record in record.log() }
                    .joined(separator: "\n")
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: working status: \n%s", ((#file as NSString).lastPathComponent), #line, #function, logs)
                let counting = workingRecords
                    .map { record in record.count() }
                    .reduce(into: WorkingRecord.Counting(), { result, next in result = result + next })
                let newTootsInTimeLineCount = workingRecords.reduce(0, { result, next in
                    return next.statusProcessType == .create ? result + 1 : result
                })
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: toot: insert %{public}ldT(%{public}ldTRQ), merge %{public}ldT(%{public}ldTRQ)", ((#file as NSString).lastPathComponent), #line, #function, newTootsInTimeLineCount, counting.status.create, mergedOldTootsInTimeline.count, counting.status.merge)
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: mastodon user: insert %{public}ld, merge %{public}ld", ((#file as NSString).lastPathComponent), #line, #function, counting.user.create, counting.user.merge)
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

extension APIService.Persist {
    
    struct WorkingIDRecord {
        var statusIDSet: Set<String>
        var reblogIDSet: Set<String>
        var userIDSet: Set<String>
        
        enum RecordType {
            case timeline
            case reblog
        }
        
        init(statusIDSet: Set<String> = Set(), reblogIDSet: Set<String> = Set(), userIDSet: Set<String> = Set()) {
            self.statusIDSet = statusIDSet
            self.reblogIDSet = reblogIDSet
            self.userIDSet = userIDSet
        }
        
        mutating func union(record: WorkingIDRecord) {
            statusIDSet = statusIDSet.union(record.statusIDSet)
            reblogIDSet = reblogIDSet.union(record.reblogIDSet)
            userIDSet = userIDSet.union(record.userIDSet)
        }
        
        static func workingID(entities: [Mastodon.Entity.Status]) -> WorkingIDRecord {
            var value = WorkingIDRecord()
            for entity in entities {
                let child = workingID(entity: entity, recordType: .timeline)
                value.union(record: child)
            }
            return value
        }
        
        private static func workingID(entity: Mastodon.Entity.Status, recordType: RecordType) -> WorkingIDRecord {
            var value = WorkingIDRecord()
            switch recordType {
            case .timeline: value.statusIDSet = Set([entity.id])
            case .reblog:   value.reblogIDSet = Set([entity.id])
            }
            value.userIDSet = Set([entity.account.id])
            
            if let reblog = entity.reblog {
                let child = workingID(entity: reblog, recordType: .reblog)
                value.union(record: child)
            }
            return value
        }
    }
    
    class WorkingRecord {
        
        let status: Toot
        let children: [WorkingRecord]
        let recordType: RecordType
        let statusProcessType: ProcessType
        let userProcessType: ProcessType
        
        init(
            status: Toot,
            children: [APIService.Persist.WorkingRecord],
            recordType: APIService.Persist.WorkingRecord.RecordType,
            tootProcessType: ProcessType,
            userProcessType: ProcessType
        ) {
            self.status = status
            self.children = children
            self.recordType = recordType
            self.statusProcessType = tootProcessType
            self.userProcessType = userProcessType
        }
        
        enum RecordType {
            case publicTimeline
            case homeTimeline
            case mentionTimeline
            case userTimeline
            case favoriteTimeline
            case searchTimeline
            
            case reblog
            
            var flag: String {
                switch self {
                case .publicTimeline:   return "P"
                case .homeTimeline:     return "H"
                case .mentionTimeline:  return "M"
                case .userTimeline:     return "U"
                case .favoriteTimeline: return "F"
                case .searchTimeline:   return "S"
                case .reblog:           return "R"
                }
            }
        }
        
        enum ProcessType {
            case create
            case merge
            
            var flag: String {
                switch self {
                case .create:   return "+"
                case .merge:    return "-"
                }
            }
        }
        
        func log(indentLevel: Int = 0) -> String {
            let indent = Array(repeating: "    ", count: indentLevel).joined()
            let tootPreview = status.content.prefix(32).replacingOccurrences(of: "\n", with: " ")
            let message = "\(indent)[\(statusProcessType.flag)\(recordType.flag)](\(status.id)) [\(userProcessType.flag)](\(status.author.id))@\(status.author.username) ~> \(tootPreview)"
            
            var childrenMessages: [String] = []
            for child in children {
                childrenMessages.append(child.log(indentLevel: indentLevel + 1))
            }
            let result = [[message] + childrenMessages]
                .flatMap { $0 }
                .joined(separator: "\n")
            
            return result
        }
        
        struct Counting {
            var status = Counter()
            var user = Counter()
            
            static func + (left: Counting, right: Counting) -> Counting {
                return Counting(
                    status: left.status + right.status,
                    user: left.user + right.user
                )
            }
            
            struct Counter {
                var create = 0
                var merge  = 0
                
                static func + (left: Counter, right: Counter) -> Counter {
                    return Counter(
                        create: left.create + right.create,
                        merge: left.merge + right.merge
                    )
                }
            }
        }
        
        func count() -> Counting {
            var counting = Counting()
            
            switch statusProcessType {
            case .create:       counting.status.create += 1
            case .merge:        counting.status.merge += 1
            }
            
            switch userProcessType {
            case .create:       counting.user.create += 1
            case .merge:        counting.user.merge += 1
            }
            
            for child in children {
                let childCounting = child.count()
                counting = counting + childCounting
            }
            
            return counting
        }
        
        // handle timelineIndex insert with APIService.Persist.createOrMergeToot
        static func createOrMergeToot(
            into managedObjectContext: NSManagedObjectContext,
            for requestMastodonUser: MastodonUser?,
            domain: String,
            entity: Mastodon.Entity.Status,
            recordType: RecordType,
            networkDate: Date,
            log: OSLog
        ) -> WorkingRecord {
            let processEntityTaskSignpostID = OSSignpostID(log: log)
            os_signpost(.begin, log: log, name: "update database - process entity: createorMergeToot", signpostID: processEntityTaskSignpostID, "process toot %{public}s", entity.id)
            defer {
                os_signpost(.end, log: log, name: "update database - process entity: createorMergeToot", signpostID: processEntityTaskSignpostID, "finish process toot %{public}s", entity.id)
            }
            
            // build tree
            let reblogRecord: WorkingRecord? = entity.reblog.flatMap { entity -> WorkingRecord in
                createOrMergeToot(into: managedObjectContext, for: requestMastodonUser, domain: domain, entity: entity, recordType: .reblog, networkDate: networkDate, log: log)
            }
            let children = [reblogRecord].compactMap { $0 }

            let (status, isTootCreated, isTootUserCreated) = APIService.CoreData.createOrMergeToot(into: managedObjectContext, for: requestMastodonUser, entity: entity, domain: domain, networkDate: networkDate, log: log)
            
            let result = WorkingRecord(
                status: status,
                children: children,
                recordType: recordType,
                tootProcessType: isTootCreated ? .create : .merge,
                userProcessType: isTootUserCreated ? .create : .merge
            )
            
            switch (result.statusProcessType, recordType) {
            case (.create, .homeTimeline), (.merge, .homeTimeline):
                guard let requestMastodonUserID = requestMastodonUser?.id else {
                    assertionFailure("Request user is required for home timeline")
                    break
                }
                let timelineIndex = status.homeTimelineIndexes?
                    .first { $0.userID == requestMastodonUserID }
                if timelineIndex == nil {
                    let timelineIndexProperty = HomeTimelineIndex.Property(domain: domain, userID: requestMastodonUserID)
                    
                    let _ = HomeTimelineIndex.insert(
                        into: managedObjectContext,
                        property: timelineIndexProperty,
                        toot: status
                    )
                } else {
                    // enity already in home timeline
                }
            default:
                break
            }
            
            return result
        }
        
    }
    
}

