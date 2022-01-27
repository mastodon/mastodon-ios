//
//  TimelineMiddleLoaderTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit
import Combine
import CoreDataStack

extension TimelineMiddleLoaderTableViewCell {
    class ViewModel {
        var disposeBag = Set<AnyCancellable>()

        @Published var isFetching = false
    }
}

extension TimelineMiddleLoaderTableViewCell.ViewModel {
    func bind(cell: TimelineMiddleLoaderTableViewCell) {
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
    func configure(
        feed: Feed,
        delegate: TimelineMiddleLoaderTableViewCellDelegate?
    ) {
        feed.publisher(for: \.isLoadingMore)
            .sink { [weak self] isLoadingMore in
                guard let self = self else { return }
                self.viewModel.isFetching = isLoadingMore
            }
            .store(in: &disposeBag)
        
        self.delegate = delegate
    }
    
}
