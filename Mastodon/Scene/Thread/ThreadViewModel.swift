//
//  ThreadViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK

class ThreadViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let rootNode: CurrentValueSubject<RootNode?, Never>
    let rootItem: CurrentValueSubject<Item?, Never>
    let cellFrameCache = NSCache<NSNumber, NSValue>()

    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    weak var tableView: UITableView?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, Item>?
    private(set) lazy var loadThreadStateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            LoadThreadState.Initial(viewModel: self),
            LoadThreadState.Loading(viewModel: self),
            LoadThreadState.Fail(viewModel: self),
            LoadThreadState.NoMore(viewModel: self),
            
        ])
        stateMachine.enter(LoadThreadState.Initial.self)
        return stateMachine
    }()
    let ancestorNodes = CurrentValueSubject<[ReplyNode], Never>([])
    let ancestorItems = CurrentValueSubject<[Item], Never>([])
    let descendantNodes = CurrentValueSubject<[LeafNode], Never>([])
    let descendantItems = CurrentValueSubject<[Item], Never>([])
    let navigationBarTitle: CurrentValueSubject<String?, Never>
    
    init(context: AppContext, optionalStatus: Status?) {
        self.context = context
        self.rootNode = CurrentValueSubject(optionalStatus.flatMap { RootNode(domain: $0.domain, statusID: $0.id, replyToID: $0.inReplyToID) })
        self.rootItem = CurrentValueSubject(optionalStatus.flatMap { Item.root(statusObjectID: $0.objectID, attribute: Item.StatusAttribute()) })
        self.navigationBarTitle = CurrentValueSubject(
            optionalStatus.flatMap { L10n.Scene.Thread.title($0.author.displayNameWithFallback) }
        )
        
        rootNode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rootNode in
                guard let self = self else { return }
                guard rootNode != nil else { return }
                self.loadThreadStateMachine.enter(LoadThreadState.Loading.self)
            }
            .store(in: &disposeBag)
        
        if optionalStatus == nil {
            rootItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] rootItem in
                    guard let self = self else { return }
                    guard case let .root(objectID, _) = rootItem else { return }
                    self.context.managedObjectContext.perform {
                        guard let status = self.context.managedObjectContext.object(with: objectID) as? Status else {
                            return
                        }
                        self.rootNode.value = RootNode(domain: status.domain, statusID: status.id, replyToID: status.inReplyToID)
                        self.navigationBarTitle.value = L10n.Scene.Thread.title(status.author.displayNameWithFallback)
                    }
                }
                .store(in: &disposeBag)
        }
        
        // descendantNodes
        
        ancestorNodes
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] nodes -> [Item]? in
                guard let self = self else { return nil }
                guard !nodes.isEmpty else { return [] }
                
                guard let diffableDataSource = self.diffableDataSource else { return nil }
                let oldSnapshot = diffableDataSource.snapshot()
                var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
                for item in oldSnapshot.itemIdentifiers {
                    switch item {
                    case .reply(let objectID, let attribute):
                        oldSnapshotAttributeDict[objectID] = attribute
                    default:
                        break
                    }
                }
                
                var items: [Item] = []
                for node in nodes {
                    let attribute = oldSnapshotAttributeDict[node.statusObjectID] ?? Item.StatusAttribute()
                    items.append(Item.reply(statusObjectID: node.statusObjectID, attribute: attribute))
                }
                
                return items.reversed()
            }
            .assign(to: \.value, on: ancestorItems)
            .store(in: &disposeBag)
        
        descendantNodes
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] nodes -> [Item]? in
                guard let self = self else { return nil }
                guard !nodes.isEmpty else { return [] }
                
                guard let diffableDataSource = self.diffableDataSource else { return nil }
                let oldSnapshot = diffableDataSource.snapshot()
                var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
                for item in oldSnapshot.itemIdentifiers {
                    switch item {
                    case .leaf(let objectID, let attribute):
                        oldSnapshotAttributeDict[objectID] = attribute
                    default:
                        break
                    }
                }
                
                var items: [Item] = []
                
                func buildThread(node: LeafNode) {
                    let attribute = oldSnapshotAttributeDict[node.objectID] ?? Item.StatusAttribute()
                    items.append(Item.leaf(statusObjectID: node.objectID, attribute: attribute))
                    // only expand the first child
                    if let firstChild = node.children.first {
                        if !node.isChildrenExpanded {
                            items.append(Item.leafBottomLoader(statusObjectID: node.objectID))
                        } else {
                            buildThread(node: firstChild)
                        }
                    }
                }
                
                for node in nodes {
                    buildThread(node: node)
                }
                return items
            }
            .assign(to: \.value, on: descendantItems)
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ThreadViewModel {
    
    struct RootNode {
        let domain: String
        let statusID: Mastodon.Entity.Status.ID
        let replyToID: Mastodon.Entity.Status.ID?
    }
    
    class ReplyNode {
        let statusID: Mastodon.Entity.Status.ID
        let statusObjectID: NSManagedObjectID
        
        init(statusID: Mastodon.Entity.Status.ID, statusObjectID: NSManagedObjectID) {
            self.statusID = statusID
            self.statusObjectID = statusObjectID
        }
        
        static func replyToThread(
            for replyToID: Mastodon.Entity.Status.ID?,
            from statuses: [Mastodon.Entity.Status],
            domain: String,
            managedObjectContext: NSManagedObjectContext
        ) -> [ReplyNode] {
            guard let replyToID = replyToID else {
                return []
            }
            
            var nodes: [ReplyNode] = []
            managedObjectContext.performAndWait {
                let request = Status.sortedFetchRequest
                request.predicate = Status.predicate(domain: domain, ids: statuses.map { $0.id })
                request.fetchLimit = statuses.count
                let objects = managedObjectContext.safeFetch(request)
                
                var objectDict: [Mastodon.Entity.Status.ID: Status] = [:]
                for object in objects {
                    objectDict[object.id] = object
                }
                var nextID: Mastodon.Entity.Status.ID? = replyToID
                while let _nextID = nextID {
                    guard let object = objectDict[_nextID] else { break }
                    nodes.append(ThreadViewModel.ReplyNode(statusID: _nextID, statusObjectID: object.objectID))
                    nextID = object.inReplyToID
                }
            }
            return nodes.reversed()
        }
    }
    
    class LeafNode {
        let statusID: Mastodon.Entity.Status.ID
        let objectID: NSManagedObjectID
        let repliesCount: Int
        let children: [LeafNode]
        
        var isChildrenExpanded: Bool = false    // default collapsed
        
        init(
            statusID: Mastodon.Entity.Status.ID,
            objectID: NSManagedObjectID,
            repliesCount: Int,
            children: [ThreadViewModel.LeafNode]
        ) {
            self.statusID = statusID
            self.objectID = objectID
            self.repliesCount = repliesCount
            self.children = children
        }
        
        static func tree(
            for statusID: Mastodon.Entity.Status.ID,
            from statuses: [Mastodon.Entity.Status],
            domain: String,
            managedObjectContext: NSManagedObjectContext
        ) -> [LeafNode] {
            // make an cache collection
            var objectDict: [Mastodon.Entity.Status.ID: Status] = [:]
            
            managedObjectContext.performAndWait {
                let request = Status.sortedFetchRequest
                request.predicate = Status.predicate(domain: domain, ids: statuses.map { $0.id })
                request.fetchLimit = statuses.count
                let objects = managedObjectContext.safeFetch(request)
                
                for object in objects {
                    objectDict[object.id] = object
                }
            }
            
            var tree: [LeafNode] = []
            let firstTierStatuses = statuses.filter { $0.inReplyToID == statusID }
            for status in firstTierStatuses {
                guard let node = node(of: status.id, objectDict: objectDict) else { continue }
                tree.append(node)
            }

            return tree
        }
        
        static func node(
            of statusID: Mastodon.Entity.Status.ID,
            objectDict: [Mastodon.Entity.Status.ID: Status]
        ) -> LeafNode? {
            guard let object = objectDict[statusID] else { return nil }
            let replies = (object.replyFrom ?? Set()).sorted(
                by: { $0.repliesCount?.intValue ?? 0 < $1.repliesCount?.intValue ?? 0 }
            )
            let children = replies.compactMap { node(of: $0.id, objectDict: objectDict) }
            return LeafNode(
                statusID: statusID,
                objectID: object.objectID,
                repliesCount: object.repliesCount?.intValue ?? 0,
                children: children
            )
        }
    }
    
}

