//
//  SearchViewController+Recommend.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import OSLog
import UIKit

extension SearchViewController {
    func setupHashTagCollectionView() {
        let header = SearchRecommendCollectionHeader()
        header.titleLabel.text = L10n.Scene.Search.Recommend.HashTag.title
        header.descriptionLabel.text = L10n.Scene.Search.Recommend.HashTag.description
        header.seeAllButton.addTarget(self, action: #selector(SearchViewController.hashtagSeeAllButtonPressed(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(header)

        hashtagCollectionView.register(SearchRecommendTagsCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchRecommendTagsCollectionViewCell.self))
        hashtagCollectionView.delegate = self

        stackView.addArrangedSubview(hashtagCollectionView)
        hashtagCollectionView.constrain([
            hashtagCollectionView.frameLayoutGuide.heightAnchor.constraint(equalToConstant: 130)
        ])
    }

    func setupAccountsCollectionView() {
        let header = SearchRecommendCollectionHeader()
        header.titleLabel.text = L10n.Scene.Search.Recommend.Accounts.title
        header.descriptionLabel.text = L10n.Scene.Search.Recommend.Accounts.description
        header.seeAllButton.addTarget(self, action: #selector(SearchViewController.accountSeeAllButtonPressed(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(header)

        accountsCollectionView.register(SearchRecommendAccountsCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchRecommendAccountsCollectionViewCell.self))
        accountsCollectionView.delegate = self

        stackView.addArrangedSubview(accountsCollectionView)
        accountsCollectionView.constrain([
            accountsCollectionView.frameLayoutGuide.heightAnchor.constraint(equalToConstant: 202)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hashtagCollectionView.collectionViewLayout.invalidateLayout()
        accountsCollectionView.collectionViewLayout.invalidateLayout()
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: indexPath: %s", (#file as NSString).lastPathComponent, #line, #function, indexPath.debugDescription)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        switch collectionView {
        case self.accountsCollectionView:
            guard let diffableDataSource = viewModel.accountDiffableDataSource else { return }
            guard let accountObjectID = diffableDataSource.itemIdentifier(for: indexPath) else { return }
            let user = context.managedObjectContext.object(with: accountObjectID) as! MastodonUser
            viewModel.accountCollectionViewItemDidSelected(mastodonUser: user, from: self)
        case self.hashtagCollectionView:
            guard let diffableDataSource = viewModel.hashtagDiffableDataSource else { return }
            guard let hashtag = diffableDataSource.itemIdentifier(for: indexPath) else { return }
            viewModel.hashtagCollectionViewItemDidSelected(hashtag: hashtag, from: self)
        default:
            break
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == hashtagCollectionView {
            return 6
        } else {
            return 12
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == hashtagCollectionView {
            return CGSize(width: 228, height: 130)
        } else {
            return CGSize(width: 257, height: 202)
        }
    }
}

extension SearchViewController {
    @objc func hashtagSeeAllButtonPressed(_ sender: UIButton) {}

    @objc func accountSeeAllButtonPressed(_ sender: UIButton) {}
}
