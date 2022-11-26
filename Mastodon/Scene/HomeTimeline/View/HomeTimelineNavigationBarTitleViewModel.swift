//
//  HomeTimelineNavigationBarTitleViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/15.
//

import Combine
import Foundation
import UIKit
import MastodonCore

final class HomeTimelineNavigationBarTitleViewModel {
    
    static let offlineCounterLimit = 3
    
    var disposeBag = Set<AnyCancellable>()
    private(set) var publishingProgressSubscription: AnyCancellable?
    
    // input
    let context: AppContext
    var networkErrorCount = CurrentValueSubject<Int, Never>(0)
    var networkErrorPublisher = PassthroughSubject<Void, Never>()
    
    // output
    let state = CurrentValueSubject<State, Never>(.logo)
    let hasNewPosts = CurrentValueSubject<Bool, Never>(false)
    let isOffline = CurrentValueSubject<Bool, Never>(false)
    let isPublishingPost = CurrentValueSubject<Bool, Never>(false)
    let isPublished = CurrentValueSubject<Bool, Never>(false)
    let publishingProgress = PassthroughSubject<Float, Never>()
    
    init(context: AppContext) {
        self.context = context
        
        networkErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.networkErrorCount.value += self.networkErrorCount.value + 1
            }
            .store(in: &disposeBag)
        
        networkErrorCount
            .receive(on: DispatchQueue.main)
            .map { count in
                return count >= HomeTimelineNavigationBarTitleViewModel.offlineCounterLimit
            }
            .assign(to: \.value, on: isOffline)
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            context.publisherService.$statusPublishers,
            context.publisherService.statusPublishResult.prepend(.failure(AppError.badRequest))
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] statusPublishers, publishResult in
            guard let self = self else { return }
            
            if statusPublishers.isEmpty {
                self.isPublishingPost.value = false
                self.isPublished.value = false
            } else {
                self.isPublishingPost.value = true
                switch publishResult {
                case .success:
                    self.isPublished.value = true
                case .failure:
                    self.isPublished.value = false
                }
            }
        }
        .store(in: &disposeBag)
        
//        context.statusPublishService.latestPublishingComposeViewModel
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] composeViewModel in
//                guard let self = self else { return }
//                guard let composeViewModel = composeViewModel,
//                      let state = composeViewModel.publishStateMachine.currentState else {
//                    self.isPublishingPost.value = false
//                    self.isPublished.value = false
//                    return
//                }
//                
//                self.isPublishingPost.value = state is ComposeViewModel.PublishState.Publishing || state is ComposeViewModel.PublishState.Fail
//                self.isPublished.value = state is ComposeViewModel.PublishState.Finish
//            }
//            .store(in: &disposeBag)
        
        Publishers.CombineLatest4(
            hasNewPosts.eraseToAnyPublisher(),
            isOffline.eraseToAnyPublisher(),
            isPublishingPost.eraseToAnyPublisher(),
            isPublished.eraseToAnyPublisher()
        )
        .map { hasNewPosts, isOffline, isPublishingPost, isPublished -> State in
            guard !isPublished else { return .publishedButton }
            guard !isPublishingPost else { return .publishingPostLabel }
            guard !isOffline else { return .offlineButton }
            guard !hasNewPosts else { return .newPostButton }
            return .logo
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.value, on: state)
        .store(in: &disposeBag)
        
//        state
//            .removeDuplicates()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] state in
//                guard let self = self else { return }
//                switch state {
//                case .publishingPostLabel:
//                    self.setupPublishingProgress()
//                default:
//                    self.suspendPublishingProgress()
//                }
//            }
//            .store(in: &disposeBag)
    }
}

extension HomeTimelineNavigationBarTitleViewModel {
    // state order by priority from low to high
    enum State: String {
        case logo
        case newPostButton
        case offlineButton
        case publishingPostLabel
        case publishedButton
    }
}

// MARK: - New post state
extension HomeTimelineNavigationBarTitleViewModel {

    func newPostsIncoming() {
        hasNewPosts.value = true
    }
    
    private func resetNewPostState() {
        hasNewPosts.value = false
    }

}

// MARK: - Offline state
extension HomeTimelineNavigationBarTitleViewModel {

    func resetOfflineCounterListener() {
        networkErrorCount.value = 0
    }
    
    func receiveLoadingStateCompletion(_ completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure:
            networkErrorPublisher.send()
        case .finished:
            resetOfflineCounterListener()
        }
    }
    
    func handleScrollViewDidScroll(_ scrollView: UIScrollView) {
        guard hasNewPosts.value else { return }
        
        let contentOffsetY = scrollView.contentOffset.y
        let isScrollToTop = contentOffsetY < -scrollView.contentInset.top
        guard isScrollToTop else { return }
        resetNewPostState()
    }
    
}

// MARK: Publish post state
//extension HomeTimelineNavigationBarTitleViewModel {
//
//    func setupPublishingProgress() {
//        let progressUpdatePublisher = Timer.publish(every: 0.016, on: .main, in: .common)     // ~ 60FPS
//            .autoconnect()
//            .share()
//            .eraseToAnyPublisher()
//
//        publishingProgressSubscription = progressUpdatePublisher
//            .map { _ in Float(0) }
//            .scan(0.0) { progress, _ -> Float in
//                return 0.95 * progress + 0.05    // progress + 0.05 * (1.0 - progress). ~ 1 sec to 0.95 (under 60FPS)
//            }
//            .subscribe(publishingProgress)
//    }
//
//    func suspendPublishingProgress() {
//        publishingProgressSubscription = nil
//        publishingProgress.send(0)
//    }
//
//}

