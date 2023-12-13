//
//  MastodonStatusThreadViewModel.swift
//  MastodonStatusThreadViewModel
//
//  Created by Cirno MainasuK on 2021-9-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonCore
import MastodonMeta

final class MastodonStatusThreadViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    @Published private(set) var deletedObjectIDs: Set<MastodonStatus.ID> = Set()

    // output
    @Published var __ancestors: [StatusItem] = []
    @Published var ancestors: [StatusItem] = []
    
    @Published var __descendants: [StatusItem] = []
    @Published var descendants: [StatusItem] = []
    
    init(context: AppContext) {
        self.context = context
        
        Publishers.CombineLatest(
            $__ancestors,
            $deletedObjectIDs
        )
        .sink { [weak self] items, deletedObjectIDs in
            guard let self = self else { return }
            let newItems = items.filter { item in
                switch item {
                case .thread(let thread):
                    return !deletedObjectIDs.contains(thread.record.id)
                default:
                    assertionFailure()
                    return false
                }
            }
            self.ancestors = newItems
        }
        .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            $__descendants,
            $deletedObjectIDs
        )
        .sink { [weak self] items, deletedObjectIDs in
            guard let self = self else { return }
            let newItems = items.filter { item in
                switch item {
                case .thread(let thread):
                    return !deletedObjectIDs.contains(thread.record.id)
                default:
                    assertionFailure()
                    return false
                }
            }
            self.descendants = newItems
        }
        .store(in: &disposeBag)
    }
    
    
}

extension MastodonStatusThreadViewModel {
    
    func appendAncestor(
        domain: String,
        nodes: [Node]
    ) {
        var newItems: [StatusItem] = []
        for node in nodes {
            let item = StatusItem.thread(.leaf(context: .init(status: node.status)))
            newItems.append(item)
        }
        
        let items = self.__ancestors + newItems
        self.__ancestors = items.removingDuplicates()
    }
    
    func appendDescendant(
        domain: String,
        nodes: [Node]
    ) {

        var newItems: [StatusItem] = []

        for node in nodes {
            let context = StatusItem.Thread.Context(status: node.status)
            let item = StatusItem.thread(.leaf(context: context))
            newItems.append(item)
            
            // second tier
            if let child = node.children.first {
                guard let secondaryStatus = node.children.first(where: { $0.status.id == child.status.id}) else { continue }
                let secondaryContext = StatusItem.Thread.Context(
                    status: secondaryStatus.status,
                    displayUpperConversationLink: true
                )
                let secondaryItem = StatusItem.thread(.leaf(context: secondaryContext))
                newItems.append(secondaryItem)

                // update first tier context
                context.displayBottomConversationLink = true
            }
        }
        
        var items = self.__descendants
        for item in newItems {
            guard !items.contains(item) else { continue }
            items.append(item)
        }
        self.__descendants = items.removingDuplicates()
    }
    
}

extension MastodonStatusThreadViewModel {
    class Node {
        let status: MastodonStatus
        let children: [Node]
        
        init(
            status: MastodonStatus,
            children: [MastodonStatusThreadViewModel.Node]
        ) {
            self.status = status
            self.children = children
        }
    }
}

extension MastodonStatusThreadViewModel.Node {
    static func replyToThread(
        for replyToID: Mastodon.Entity.Status.ID?,
        from statuses: [Mastodon.Entity.Status]
    ) -> [MastodonStatusThreadViewModel.Node] {
        guard let replyToID = replyToID else {
            return []
        }
        
        var dict: [Mastodon.Entity.Status.ID: Mastodon.Entity.Status] = [:]
        for status in statuses {
            dict[status.id] = status
        }
        
        var nextID: Mastodon.Entity.Status.ID? = replyToID
        var nodes: [MastodonStatusThreadViewModel.Node] = []
        while let _nextID = nextID {
            guard let status = dict[_nextID] else { break }
            nodes.append(MastodonStatusThreadViewModel.Node(
                status: .fromEntity(status),
                children: []
            ))
            nextID = status.inReplyToID
        }
        
        return nodes
    }
}

extension MastodonStatusThreadViewModel.Node {
    static func children(
        of status: MastodonStatus,
        from statuses: [Mastodon.Entity.Status]
    ) -> [MastodonStatusThreadViewModel.Node] {
        var dictionary: [Mastodon.Entity.Status.ID: Mastodon.Entity.Status] = [:]
        var mapping: [Mastodon.Entity.Status.ID: Set<Mastodon.Entity.Status.ID>] = [:]
        
        for status in statuses {
            dictionary[status.id] = status
            guard let replyToID = status.inReplyToID else { continue }
            if var set = mapping[replyToID] {
                set.insert(status.id)
                mapping[replyToID] = set
            } else {
                mapping[replyToID] = Set([status.id])
            }
        }
        
        var children: [MastodonStatusThreadViewModel.Node] = []
        let replies = Array(mapping[status.id] ?? Set())
            .compactMap { dictionary[$0] }
            .sorted(by: { $0.createdAt > $1.createdAt })
        for reply in replies {
            let child = child(of: reply, dictionary: dictionary, mapping: mapping)
            children.append(child)
        }
        return children
    }
    
    static func child(
        of status: Mastodon.Entity.Status,
        dictionary: [Mastodon.Entity.Status.ID: Mastodon.Entity.Status],
        mapping: [Mastodon.Entity.Status.ID: Set<Mastodon.Entity.Status.ID>]
    ) -> MastodonStatusThreadViewModel.Node {
        let childrenIDs = mapping[status.id] ?? []
        let children = Array(childrenIDs)
            .compactMap { dictionary[$0] }
            .sorted(by: { $0.createdAt > $1.createdAt })
            .map { status in child(of: status, dictionary: dictionary, mapping: mapping) }
        return MastodonStatusThreadViewModel.Node(
            status: .fromEntity(status),
            children: children
        )
    }
    
}

