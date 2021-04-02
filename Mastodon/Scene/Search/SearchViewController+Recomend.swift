//
//  SearchViewController+Recomend.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
import MastodonSDK
import OSLog
import UIKit

extension SearchViewController {
    func setupHashTagCollectionView() {
        let header = SearchRecommendCollectionHeader()
        header.titleLabel.text = L10n.Scene.Search.Recommend.HashTag.title
        header.descriptionLabel.text = L10n.Scene.Search.Recommend.HashTag.description
        header.seeAllButton.addTarget(self, action: #selector(SearchViewController.hashTagSeeAllButtonPressed(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(header)

        hashTagCollectionView.register(SearchRecommendTagsCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchRecommendTagsCollectionViewCell.self))
        hashTagCollectionView.delegate = self

        stackView.addArrangedSubview(hashTagCollectionView)
        hashTagCollectionView.constrain([
            hashTagCollectionView.frameLayoutGuide.heightAnchor.constraint(equalToConstant: 130)
        ])

        viewModel.requestRecommendHashTags()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !self.viewModel.recommendHashTags.isEmpty {
                    let dataSource = RecomendHashTagSection.collectionViewDiffableDataSource(for: self.hashTagCollectionView)
                    var snapshot = NSDiffableDataSourceSnapshot<RecomendHashTagSection, Mastodon.Entity.Tag>()
                    snapshot.appendSections([.main])
                    snapshot.appendItems(self.viewModel.recommendHashTags, toSection: .main)
                    dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
                    self.hashTagDiffableDataSource = dataSource
                }
            } receiveValue: { _ in
            }
            .store(in: &disposeBag)
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

        viewModel.requestRecommendAccounts()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !self.viewModel.recommendAccounts.isEmpty {
                    let dataSource = RecommendAccountSection.collectionViewDiffableDataSource(for: self.accountsCollectionView)
                    var snapshot = NSDiffableDataSourceSnapshot<RecommendAccountSection, Mastodon.Entity.Account>()
                    snapshot.appendSections([.main])
                    snapshot.appendItems(self.viewModel.recommendAccounts, toSection: .main)
                    dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
                    self.accountDiffableDataSource = dataSource
                }
            } receiveValue: { _ in
            }
            .store(in: &disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hashTagCollectionView.collectionViewLayout.invalidateLayout()
        accountsCollectionView.collectionViewLayout.invalidateLayout()
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: indexPath: %s", (#file as NSString).lastPathComponent, #line, #function, indexPath.debugDescription)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == hashTagCollectionView {
            return 6
        } else {
            return 12
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == hashTagCollectionView {
            return CGSize(width: 228, height: 130)
        } else {
            return CGSize(width: 257, height: 202)
        }
    }
}

extension SearchViewController {
    @objc func hashTagSeeAllButtonPressed(_ sender: UIButton) {}

    @objc func accountSeeAllButtonPressed(_ sender: UIButton) {}
}
