//
//  SearchViewController+recomemndView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
import UIKit


extension SearchViewController {
    func setuprecomemndView() {
        recomemndView.dataSource = self
        recomemndView.delegate = self
    }
}

extension SearchViewController: UICollectionViewDelegate {
    
}

extension SearchViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    
}
