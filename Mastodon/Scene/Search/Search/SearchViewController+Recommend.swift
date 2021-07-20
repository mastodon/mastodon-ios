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
        header.seeAllButton.isHidden = true
        stackView.addArrangedSubview(header)

        hashtagCollectionView.register(SearchRecommendTagsCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchRecommendTagsCollectionViewCell.self))
        hashtagCollectionView.delegate = self

        hashtagCollectionView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(hashtagCollectionView)
        NSLayoutConstraint.activate([
            hashtagCollectionView.frameLayoutGuide.heightAnchor.constraint(equalToConstant: CGFloat(SearchViewController.hashtagCardHeight))
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

        accountsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(accountsCollectionView)
        NSLayoutConstraint.activate([
            accountsCollectionView.frameLayoutGuide.heightAnchor.constraint(equalToConstant: CGFloat(SearchViewController.accountCardHeight))
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
            let mastodonUser = context.managedObjectContext.object(with: accountObjectID) as! MastodonUser
            let viewModel = ProfileViewModel(context: context, optionalMastodonUser: mastodonUser)
            DispatchQueue.main.async {
                self.coordinator.present(scene: .profile(viewModel: viewModel), from: self, transition: .show)
            }
        case self.hashtagCollectionView:
            guard let diffableDataSource = viewModel.hashtagDiffableDataSource else { return }
            guard let hashtag = diffableDataSource.itemIdentifier(for: indexPath) else { return }
            let (tagInCoreData, _) = APIService.CoreData.createOrMergeTag(into: context.managedObjectContext, entity: hashtag)
            let viewModel = HashtagTimelineViewModel(context: context, hashtag: tagInCoreData.name)
            DispatchQueue.main.async {
                self.coordinator.present(scene: .hashtagTimeline(viewModel: viewModel), from: self, transition: .show)
            }
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
            return CGSize(width: 228, height: SearchViewController.hashtagCardHeight)
        } else {
            return CGSize(width: 257, height: SearchViewController.accountCardHeight)
        }
    }
}

extension SearchViewController {
    @objc func hashtagSeeAllButtonPressed(_ sender: UIButton) {}

    @objc func accountSeeAllButtonPressed(_ sender: UIButton) {
        if self.viewModel.recommendAccounts.isEmpty {
            return
        }
        let viewModel = SuggestionAccountViewModel(context: context, accounts: self.viewModel.recommendAccounts)
        coordinator.present(scene: .suggestionAccount(viewModel: viewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
}
