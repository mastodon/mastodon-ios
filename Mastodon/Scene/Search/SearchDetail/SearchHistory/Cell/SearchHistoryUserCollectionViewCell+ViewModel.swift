//
//  SearchHistoryUserCollectionViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import Foundation
import CoreDataStack

extension SearchHistoryUserCollectionViewCell {
    final class ViewModel {
        let value: MastodonUser
        
        init(value: MastodonUser) {
            self.value = value
        }
    }
}

extension SearchHistoryUserCollectionViewCell {
    func configure(
        viewModel: ViewModel
    ) {
        userView.configure(user: viewModel.value)
    }
}
