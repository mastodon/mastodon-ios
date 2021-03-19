//
//  APIService+Persist+PersistMemo.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-10.
//

import os.log
import Foundation
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService.Persist {
    
    class PersistMemo<T, U> {
        
        let status: T
        let children: [PersistMemo<T, U>]
        let memoType: MemoType
        let statusProcessType: ProcessType
        let authorProcessType: ProcessType
        
        enum MemoType {
            case homeTimeline
            case mentionTimeline
            case userTimeline
            case publicTimeline
            case likeList
            case searchList
            case lookUp
            
            case reblog
            
            var flag: String {
                switch self {
                case .homeTimeline:     return "H"
                case .mentionTimeline:  return "M"
                case .userTimeline:     return "U"
                case .publicTimeline:   return "P"
                case .likeList:         return "L"
                case .searchList:       return "S"
                case .lookUp:           return "LU"
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
                case .merge:    return "~"
                }
            }
        }
        
        init(
            status: T,
            children: [PersistMemo<T, U>],
            memoType: MemoType,
            statusProcessType: ProcessType,
            authorProcessType: ProcessType
        ) {
            self.status = status
            self.children = children
            self.memoType = memoType
            self.statusProcessType = statusProcessType
            self.authorProcessType = authorProcessType
        }
        
    }
    
}

extension APIService.Persist.PersistMemo {
    
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
        
        switch authorProcessType {
        case .create:       counting.user.create += 1
        case .merge:        counting.user.merge += 1
        }
        
        for child in children {
            let childCounting = child.count()
            counting = counting + childCounting
        }
        
        return counting
    }
    
}

extension APIService.Persist.PersistMemo where T == Toot, U == MastodonUser {
    
    static func createOrMergeToot(
        into managedObjectContext: NSManagedObjectContext,
        for requestMastodonUser: MastodonUser?,
        requestMastodonUserID: MastodonUser.ID?,
        domain: String,
        entity: Mastodon.Entity.Status,
        memoType: MemoType,
        tootCache: APIService.Persist.PersistCache<T>?,
        userCache: APIService.Persist.PersistCache<U>?,
        networkDate: Date,
        log: OSLog
    ) -> APIService.Persist.PersistMemo<T, U> {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeToot", signpostID: processEntityTaskSignpostID, "process toot %{public}s", entity.id)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeToot", signpostID: processEntityTaskSignpostID, "finish process toot %{public}s", entity.id)
        }
        
        // build tree
        let reblogMemo = entity.reblog.flatMap { entity -> APIService.Persist.PersistMemo<T, U> in
            createOrMergeToot(
                into: managedObjectContext,
                for: requestMastodonUser,
                requestMastodonUserID: requestMastodonUserID,
                domain: domain,
                entity: entity,
                memoType: .reblog,
                tootCache: tootCache,
                userCache: userCache,
                networkDate: networkDate,
                log: log
            )
        }
        let children = [reblogMemo].compactMap { $0 }


        let (toot, isTootCreated, isMastodonUserCreated) = APIService.CoreData.createOrMergeStatus(
            into: managedObjectContext,
            for: requestMastodonUser,
            domain: domain,
            entity: entity,
            tootCache: tootCache,
            userCache: userCache,
            networkDate: networkDate,
            log: log
        )
        let memo = APIService.Persist.PersistMemo<T, U>(
            status: toot,
            children: children,
            memoType: memoType,
            statusProcessType: isTootCreated ? .create : .merge,
            authorProcessType: isMastodonUserCreated ? .create : .merge
        )
        
        switch (memo.statusProcessType, memoType) {
        case (.create, .homeTimeline), (.merge, .homeTimeline):
            let timelineIndex = toot.homeTimelineIndexes?
                .first { $0.userID == requestMastodonUserID }
            guard let requestMastodonUserID = requestMastodonUserID else {
                assertionFailure()
                break
            }
            if timelineIndex == nil {
                // make it indexed
                let timelineIndexProperty = HomeTimelineIndex.Property(domain: domain, userID: requestMastodonUserID)
                let _ = HomeTimelineIndex.insert(into: managedObjectContext, property: timelineIndexProperty, toot: toot)
            } else {
                // enity already in home timeline
            }
        case (.create, .mentionTimeline), (.merge, .mentionTimeline):
            break
            // TODO:
        default:
            break
        }
        
        return memo
    }
    
    func log(indentLevel: Int = 0) -> String {
        let indent = Array(repeating: "    ", count: indentLevel).joined()
        let preview = status.content.prefix(32).replacingOccurrences(of: "\n", with: " ")
        let message = "\(indent)[\(statusProcessType.flag)\(memoType.flag)](\(status.id)) [\(authorProcessType.flag)](\(status.author.id))@\(status.author.username) ~> \(preview)"
        
        var childrenMessages: [String] = []
        for child in children {
            childrenMessages.append(child.log(indentLevel: indentLevel + 1))
        }
        let result = [[message] + childrenMessages]
            .flatMap { $0 }
            .joined(separator: "\n")
        
        return result
    }
    
}

