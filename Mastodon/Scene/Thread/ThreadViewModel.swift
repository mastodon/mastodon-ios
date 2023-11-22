//
//  ThreadViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

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
    @Published var hasPendingStatusEditReload = false
    
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

        $root
            .receive(on: DispatchQueue.main)
            .sink { [weak self] root in
                guard let self = self else { return }
                guard case let .root(threadContext) = root else { return }
                let status = threadContext.status
                
                // bind threadContext
                self.threadContext = .init(
                    domain: authContext.mastodonAuthenticationBox.domain, //status.domain,
                    statusID: status.id,
                    replyToID: status.entity.inReplyToID
                )
                
                // bind titleView
                self.navigationBarTitle = {
                    let title = L10n.Scene.Thread.title(status.entity.account.displayNameWithFallback)
                    let content = MastodonContent(content: title, emojis: status.entity.account.emojis?.asDictionary ?? [:])
                    return try? MastodonMetaContent.convert(document: content)
                }()
            }
            .store(in: &disposeBag)
        
        context.publisherService
            .statusPublishResult
            .sink { [weak self] value in
                if case let Result.success(result) = value, case StatusPublishResult.edit = result {
                    self?.hasPendingStatusEditReload = true
                }
            }
            .store(in: &disposeBag)
    }
    

}

extension ThreadViewModel {
    
    struct ThreadContext {
        let domain: String
        let statusID: Mastodon.Entity.Status.ID
        let replyToID: Mastodon.Entity.Status.ID?
    }
    
}
