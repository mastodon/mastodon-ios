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
    let authContext: AuthContext
    let mastodonStatusThreadViewModel: MastodonStatusThreadViewModel
    
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
        authContext: AuthContext,
        optionalRoot: StatusItem.Thread?
    ) {
        self.context = context
        self.authContext = authContext
        self.root = optionalRoot
        self.mastodonStatusThreadViewModel = MastodonStatusThreadViewModel(context: context)
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
