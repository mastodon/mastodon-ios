//
//  SearchViewController+recommendView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
import UIKit


extension SearchViewController {
    func setuprecommendView() {
        recommendView.register(SearchRecommendTagsCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchRecommendTagsCollectionViewCell.self))
        recommendView.dataSource = self
        recommendView.delegate = self
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recommendView.collectionViewLayout.invalidateLayout()
    }
}

extension SearchViewController: UICollectionViewDelegate {
    
}

extension SearchViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return (self.viewModel.recommendAccounts.isEmpty ? 0 : 1) + (self.viewModel.recommendHashTags.isEmpty ? 0 : 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return viewModel.recommendHashTags.count
        case 1:
            return viewModel.recommendAccounts.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    
}
