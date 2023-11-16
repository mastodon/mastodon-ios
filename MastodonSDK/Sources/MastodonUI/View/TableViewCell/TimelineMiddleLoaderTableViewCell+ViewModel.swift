//
//  TimelineMiddleLoaderTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit
import Combine
import MastodonSDK

extension TimelineMiddleLoaderTableViewCell {
    public class ViewModel {
        var disposeBag = Set<AnyCancellable>()

        @Published var isFetching = false
    }
}

extension TimelineMiddleLoaderTableViewCell.ViewModel {
    public func bind(cell: TimelineMiddleLoaderTableViewCell) {
        $isFetching
            .sink { isFetching in
                if isFetching {
                    cell.startAnimating()
                } else {
                    cell.stopAnimating()
                }
            }
            .store(in: &disposeBag)
    }
}


extension TimelineMiddleLoaderTableViewCell {
    public func configure(
        feed: FeedItem,
        delegate: TimelineMiddleLoaderTableViewCellDelegate?
    ) {
        self.viewModel.isFetching = feed.isLoadingMore
        
        self.delegate = delegate
    }
    
}
