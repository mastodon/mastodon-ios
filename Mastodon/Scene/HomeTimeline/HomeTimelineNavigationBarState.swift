//
//  HomeTimelineNavigationBarState.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/15.
//

import Combine
import Foundation
import UIKit

final class HomeTimelineNavigationBarState {
    static let errorCountMax: Int = 3
    var disposeBag = Set<AnyCancellable>()
    var errorCountDownDispose: AnyCancellable?
    var networkErrorCountSubject = PassthroughSubject<Bool, Never>()
    
    var titleViewBeforePublishing: UIView? // used for restore titleView after published
    
    var newTopContent = CurrentValueSubject<Bool, Never>(false)
    var newBottomContent = CurrentValueSubject<Bool, Never>(false)
    var hasContentBeforeFetching: Bool = true
    
    weak var viewController: HomeTimelineViewController?
    
    init() {
        reCountdown()
        subscribeNewContent()
        addGesture()
    }
}

extension HomeTimelineNavigationBarState {
    func showOfflineInNavigationBar() {
        viewController?.navigationItem.titleView = HomeTimelineNavigationBarView.offlineView
    }
    
    func showNewPostsInNavigationBar() {
        viewController?.navigationItem.titleView = HomeTimelineNavigationBarView.newPostsView
    }
    
    func showPublishingNewPostInNavigationBar() {
        titleViewBeforePublishing = viewController?.navigationItem.titleView
    }
    
    func showPublishedInNavigationBar() {
        viewController?.navigationItem.titleView = HomeTimelineNavigationBarView.publishedView
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            if let titleView = self.titleViewBeforePublishing, let navigationItem = self.viewController?.navigationItem {
                navigationItem.titleView = titleView
            }
        }
    }
    
    func showMastodonLogoInNavigationBar() {
        viewController?.navigationItem.titleView = HomeTimelineNavigationBarView.mastodonLogoTitleView
    }
}

extension HomeTimelineNavigationBarState {
    func handleScrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        print(contentOffsetY)
        let isTop = contentOffsetY < -scrollView.contentInset.top
        if isTop {
            newTopContent.value = false
            showMastodonLogoInNavigationBar()
        }
        let isBottom = contentOffsetY > max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height - scrollView.frame.height + scrollView.adjustedContentInset.bottom)
        if isBottom {
            newBottomContent.value = false
            showMastodonLogoInNavigationBar()
        }
    }
    
    func addGesture() {
        let tapGesture = UITapGestureRecognizer.singleTapGestureRecognizer
        tapGesture.addTarget(self, action: #selector(newPostsNewDidPressed))
        HomeTimelineNavigationBarView.newPostsView.addGestureRecognizer(tapGesture)
    }
    
    @objc func newPostsNewDidPressed() {
        if newTopContent.value == true {
            scrollToDirection(direction: .top)
        }
        if newBottomContent.value == true {
            scrollToDirection(direction: .bottom)
        }
    }
    
    func scrollToDirection(direction: UIScrollView.ScrollDirection) {
        viewController?.tableView.scroll(to: direction, animated: true)
    }
}

extension HomeTimelineNavigationBarState {
    func subscribeNewContent() {
        newTopContent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newContent in
                guard let self = self else { return }
                if self.hasContentBeforeFetching, newContent {
                    self.showNewPostsInNavigationBar()
                }
                if newContent {
                    self.newBottomContent.value = false
                }
            }
            .store(in: &disposeBag)
        newBottomContent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newContent in
                guard let self = self else { return }
                if newContent {
                    self.showNewPostsInNavigationBar()
                }
                if (newContent) {
                    self.newTopContent.value = false
                }
            }
            .store(in: &disposeBag)
    }

    func reCountdown() {
        errorCountDownDispose = networkErrorCountSubject
            .scan(0) { value, _ in value + 1 }
            .sink(receiveValue: { [weak self] errorCount in
                guard let self = self else { return }
                if errorCount >= HomeTimelineNavigationBarState.errorCountMax {
                    self.showOfflineInNavigationBar()
                }
            })
    }
    
    func receiveCompletion(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure:
            networkErrorCountSubject.send(false)
        case .finished:
            reCountdown()
        }
    }
}
