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
import MastodonMeta
import MastodonAsset
import MastodonCore
import MastodonLocalization

class ThreadViewModel {
    
    let logger = Logger(subsystem: "ThreadViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    var rootItemObserver: AnyCancellable?
    
    // input
    let context: AppContext
    let mastodonStatusThreadViewModel: MastodonStatusThreadViewModel

//    let cellFrameCache = NSCache<NSNumber, NSValue>()
//    let existStatusFetchedResultsController: StatusFetchedResultsController

//    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
//    weak var tableView: UITableView?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    @Published var root: StatusItem.Thread?
    @Published var threadContext: ThreadContext?
    
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
    @Published var navigationBarTitle: MastodonMetaContent?
    
    init(
        context: AppContext,
        optionalRoot: StatusItem.Thread?
    ) {
        self.context = context
        self.root = optionalRoot
        self.mastodonStatusThreadViewModel = MastodonStatusThreadViewModel(context: context)
//        self.rootNode = CurrentValueSubject(optionalStatus.flatMap { RootNode(domain: $0.domain, statusID: $0.id, replyToID: $0.inReplyToID) })
//        self.rootItem = CurrentValueSubject(optionalStatus.flatMap { Item.root(statusObjectID: $0.objectID, attribute: Item.StatusAttribute()) })
//        self.existStatusFetchedResultsController = StatusFetchedResultsController(managedObjectContext: context.managedObjectContext, domain: nil, additionalTweetPredicate: nil)
//        self.navigationBarTitle = CurrentValueSubject(
//            optionalStatus.flatMap { L10n.Scene.Thread.title($0.author.displayNameWithFallback) })
//        self.navigationBarTitleEmojiMeta = CurrentValueSubject(optionalStatus.flatMap { $0.author.emojis.asDictionary } ?? [:])
        // end init
        
        ManagedObjectObserver.observe(context: context.managedObjectContext)
            .sink(receiveCompletion: { completion in
                // do nohting
            }, receiveValue: { [weak self] changes in
                guard let self = self else { return }
                
                let objectIDs: [NSManagedObjectID] = changes.changeTypes.compactMap { changeType in
                    guard case let .delete(object) = changeType else { return nil }
                    return object.objectID
                }
                
                self.delete(objectIDs: objectIDs)
            })
            .store(in: &disposeBag)
        
//        // bind fetcher domain
//        context.authenticationService.activeMastodonAuthenticationBox
//            .receive(on: RunLoop.main)
//            .sink { [weak self] box in
//                guard let self = self else { return }
//                self.existStatusFetchedResultsController.domain.value = box?.domain
//            }
//            .store(in: &disposeBag)
//
//        rootNode
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] rootNode in
//                guard let self = self else { return }
//                guard rootNode != nil else { return }
//                self.loadThreadStateMachine.enter(LoadThreadState.Loading.self)
//            }
//            .store(in: &disposeBag)
        
        $root
            .receive(on: DispatchQueue.main)
            .sink { [weak self] root in
                guard let self = self else { return }
                guard case let .root(threadContext) = root else { return }
                guard let status = threadContext.status.object(in: self.context.managedObjectContext) else { return }
                
                // bind threadContext
                self.threadContext = .init(
                    domain: status.domain,
                    statusID: status.id,
                    replyToID: status.inReplyToID
                )
                
                // bind titleView
                self.navigationBarTitle = {
                    let title = L10n.Scene.Thread.title(status.author.displayNameWithFallback)
                    let content = MastodonContent(content: title, emojis: status.author.emojis.asDictionary)
                    return try? MastodonMetaContent.convert(document: content)
                }()
            }
            .store(in: &disposeBag)

//        rootItem
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] rootItem in
//                guard let self = self else { return }
//                guard case let .root(objectID, _) = rootItem else { return }
//                self.context.managedObjectContext.perform {
//                    guard let status = self.context.managedObjectContext.object(with: objectID) as? Status else {
//                        return
//                    }
//                    self.rootItemObserver = ManagedObjectObserver.observe(object: status)
//                        .receive(on: DispatchQueue.main)
//                        .sink(receiveCompletion: { _ in
//                            // do nothing
//                        }, receiveValue: { [weak self] change in
//                            guard let self = self else { return }
//                            switch change.changeType {
//                            case .delete:
//                                self.rootItem.value = nil
//                            default:
//                                break
//                            }
//                        })
//                }
//            }
//            .store(in: &disposeBag)
//                
//        ancestorNodes
//            .receive(on: DispatchQueue.main)
//            .compactMap { [weak self] nodes -> [Item]? in
//                guard let self = self else { return nil }
//                guard !nodes.isEmpty else { return [] }
//                
//                guard let diffableDataSource = self.diffableDataSource else { return nil }
//                let oldSnapshot = diffableDataSource.snapshot()
//                var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
//                for item in oldSnapshot.itemIdentifiers {
//                    switch item {
//                    case .reply(let objectID, let attribute):
//                        oldSnapshotAttributeDict[objectID] = attribute
//                    default:
//                        break
//                    }
//                }
//                
//                var items: [Item] = []
//                for node in nodes {
//                    let attribute = oldSnapshotAttributeDict[node.statusObjectID] ?? Item.StatusAttribute()
//                    items.append(Item.reply(statusObjectID: node.statusObjectID, attribute: attribute))
//                }
//                
//                return items.reversed()
//            }
//            .assign(to: \.value, on: ancestorItems)
//            .store(in: &disposeBag)
//        
//        descendantNodes
//            .receive(on: DispatchQueue.main)
//            .compactMap { [weak self] nodes -> [Item]? in
//                guard let self = self else { return nil }
//                guard !nodes.isEmpty else { return [] }
//                
//                guard let diffableDataSource = self.diffableDataSource else { return nil }
//                let oldSnapshot = diffableDataSource.snapshot()
//                var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
//                for item in oldSnapshot.itemIdentifiers {
//                    switch item {
//                    case .leaf(let objectID, let attribute):
//                        oldSnapshotAttributeDict[objectID] = attribute
//                    default:
//                        break
//                    }
//                }
//                
//                var items: [Item] = []
//                
//                func buildThread(node: LeafNode) {
//                    let attribute = oldSnapshotAttributeDict[node.objectID] ?? Item.StatusAttribute()
//                    items.append(Item.leaf(statusObjectID: node.objectID, attribute: attribute))
//                    // only expand the first child
//                    if let firstChild = node.children.first {
//                        if !node.isChildrenExpanded {
//                            items.append(Item.leafBottomLoader(statusObjectID: node.objectID))
//                        } else {
//                            buildThread(node: firstChild)
//                        }
//                    }
//                }
//                
//                for node in nodes {
//                    buildThread(node: node)
//                }
//                return items
//            }
//            .assign(to: \.value, on: descendantItems)
//            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ThreadViewModel {
    
    struct ThreadContext {
        let domain: String
        let statusID: Mastodon.Entity.Status.ID
        let replyToID: Mastodon.Entity.Status.ID?
    }
    
}

extension ThreadViewModel {
    func delete(objectIDs: [NSManagedObjectID]) {
        if let root = self.root,
           case let .root(threadContext) = root,
           objectIDs.contains(threadContext.status.objectID)
        {
            self.root = nil
        }

        self.mastodonStatusThreadViewModel.delete(objectIDs: objectIDs)
    }
}
