//
//  HashtagTimelineViewModel.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/30.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
import MastodonCore

final class HashtagTimelineViewModel {
    
    let logger = Logger(subsystem: "HashtagTimelineViewModel", category: "ViewModel")
    
    let hashtag: String
    
    var disposeBag = Set<AnyCancellable>()
    
    var needLoadMiddleIndex: Int? = nil

    // input
    let context: AppContext
    let authContext: AuthContext
    let fetchedResultsController: StatusFetchedResultsController
    let isFetchingLatestTimeline = CurrentValueSubject<Bool, Never>(false)
    let timelinePredicate = CurrentValueSubject<NSPredicate?, Never>(nil)
    let hashtagEntity = CurrentValueSubject<Mastodon.Entity.Tag?, Never>(nil)
    let listBatchFetchViewModel = ListBatchFetchViewModel()

    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    let didLoadLatest = PassthroughSubject<Void, Never>()
    let hashtagDetails = CurrentValueSubject<Mastodon.Entity.Tag?, Never>(nil)

    // bottom loader
    private(set) lazy var stateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.Loading(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    init(context: AppContext, authContext: AuthContext, hashtag: String) {
        self.context  = context
        self.authContext = authContext
        self.hashtag = hashtag
        self.fetchedResultsController = StatusFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: authContext.mastodonAuthenticationBox.domain,
            additionalTweetPredicate: nil
        )
        updateTagInformation()
        // end init
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func viewWillAppear() {
        let predicate = Tag.predicate(
            domain: authContext.mastodonAuthenticationBox.domain,
            name: hashtag
        )

        guard
            let object = Tag.findOrFetch(in: context.managedObjectContext, matching: predicate)
        else {
            return hashtagDetails.send(hashtagDetails.value?.copy(following: false))
        }

        hashtagDetails.send(hashtagDetails.value?.copy(following: object.following))
    }
}

extension HashtagTimelineViewModel {
    func followTag() {
        self.hashtagDetails.send(hashtagDetails.value?.copy(following: true))
        Task { @MainActor in
            let tag = try? await context.apiService.followTag(
                for: hashtag,
                authenticationBox: authContext.mastodonAuthenticationBox
            ).value
            self.hashtagDetails.send(tag)
        }
    }
    
    func unfollowTag() {
        self.hashtagDetails.send(hashtagDetails.value?.copy(following: false))
        Task { @MainActor in
            let tag = try? await context.apiService.unfollowTag(
                for: hashtag,
                authenticationBox: authContext.mastodonAuthenticationBox
            ).value
            self.hashtagDetails.send(tag)
        }
    }
}

private extension HashtagTimelineViewModel {
    func updateTagInformation() {
        Task { @MainActor in
            let tag = try? await context.apiService.getTagInformation(
                for: hashtag,
                authenticationBox: authContext.mastodonAuthenticationBox
            ).value
            
            self.hashtagDetails.send(tag)
        }
    }
}
