//
//  ListBatchFetchViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-10.
//

import UIKit
import Combine

// ref: Texture.ASBatchFetchingDelegate
final class ListBatchFetchViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // timer running on `common` mode
    let timerPublisher = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()
    
    // input
    private(set) weak var scrollView: UIScrollView?
    let hasMore = CurrentValueSubject<Bool, Never>(true)
    
    // output
    let shouldFetch = PassthroughSubject<Void, Never>()
    
    init() {
        Publishers.CombineLatest(
            hasMore,
            timerPublisher
        )
        .sink { [weak self] hasMore, _ in
            guard let self = self else { return }
            guard hasMore else { return }
            guard let scrollView = self.scrollView else { return }
            
            // skip trigger if user interacting
            if scrollView.isDragging || scrollView.isTracking { return }
            
            // send fetch request
            if scrollView.contentSize.height < scrollView.frame.height {
                self.shouldFetch.send()
            } else {
                let frame = scrollView.frame
                let contentOffset = scrollView.contentOffset
                let contentSize = scrollView.contentSize
                
                let visibleBottomY = contentOffset.y + frame.height
                let offset = 2 * frame.height
                let fetchThrottleOffsetY = contentSize.height - offset
                
                if visibleBottomY > fetchThrottleOffsetY {
                    self.shouldFetch.send()
                }
            }
        }
        .store(in: &disposeBag)
    }
    
}

extension ListBatchFetchViewModel {
    func setup(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }
}
