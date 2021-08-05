//
//  RecommendAccountSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import MetaTextKit
import MastodonMeta
import Combine

enum RecommendAccountSection: Equatable, Hashable {
    case main
}

extension RecommendAccountSection {
    static func collectionViewDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency,
        delegate: SearchRecommendAccountsCollectionViewCellDelegate,
        managedObjectContext: NSManagedObjectContext
    ) -> UICollectionViewDiffableDataSource<RecommendAccountSection, NSManagedObjectID> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak delegate] collectionView, indexPath, objectID -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SearchRecommendAccountsCollectionViewCell.self), for: indexPath) as! SearchRecommendAccountsCollectionViewCell
            managedObjectContext.performAndWait {
                let user = managedObjectContext.object(with: objectID) as! MastodonUser
                configure(cell: cell, user: user, dependency: dependency)
            }
            cell.delegate = delegate
            return cell
        }
    }
    
    static func configure(
        cell: SearchRecommendAccountsCollectionViewCell,
        user: MastodonUser,
        dependency: NeedsDependency
    ) {
        configureContent(cell: cell, user: user)
        
        if let currentMastodonUser = dependency.context.authenticationService.activeMastodonAuthentication.value?.user {
            configureFollowButton(with: user, currentMastodonUser: currentMastodonUser, followButton: cell.followButton)
        }
        
        Publishers.CombineLatest(
            ManagedObjectObserver.observe(object: user).eraseToAnyPublisher().mapError { $0 as Error },
            dependency.context.authenticationService.activeMastodonAuthentication.setFailureType(to: Error.self)
        )
        .receive(on: DispatchQueue.main)
        .sink { _ in
            // do nothing
        } receiveValue: { [weak cell] change, authentication in
            guard let cell = cell else { return }
            guard case .update(let object) = change.changeType,
                  let user = object as? MastodonUser else { return }
            guard let currentMastodonUser = authentication?.user else { return }
            
            configureFollowButton(with: user, currentMastodonUser: currentMastodonUser, followButton: cell.followButton)
        }
        .store(in: &cell.disposeBag)
        
    }
    
    static func configureContent(
        cell: SearchRecommendAccountsCollectionViewCell,
        user: MastodonUser
    ) {
        do {
            let mastodonContent = MastodonContent(content: user.displayNameWithFallback, emojis: user.emojiMeta)
            let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
            cell.displayNameLabel.configure(content: metaContent)
        } catch {
            let metaContent = PlaintextMetaContent(string: user.displayNameWithFallback)
            cell.displayNameLabel.configure(content: metaContent)
        }
        cell.acctLabel.text = "@" + user.acct
        cell.avatarImageView.af.setImage(
            withURL: user.avatarImageURLWithFallback(domain: user.domain),
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        )
        cell.headerImageView.af.setImage(
            withURL: URL(string: user.header)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        ) { [weak cell] _ in
            // guard let cell = cell else { return }
        }
    }
    
    static func configureFollowButton(
        with mastodonUser: MastodonUser,
        currentMastodonUser: MastodonUser,
        followButton: HighlightDimmableButton
    ) {
        let relationshipActionSet = relationShipActionSet(mastodonUser: mastodonUser, currentMastodonUser: currentMastodonUser)
        followButton.setTitle(relationshipActionSet.title, for: .normal)
    }
    
    static func relationShipActionSet(
        mastodonUser: MastodonUser,
        currentMastodonUser: MastodonUser
    ) -> ProfileViewModel.RelationshipActionOptionSet {
        var relationshipActionSet = ProfileViewModel.RelationshipActionOptionSet([.follow])
        let isFollowing = mastodonUser.followingBy.flatMap { $0.contains(currentMastodonUser) } ?? false
        if isFollowing {
            relationshipActionSet.insert(.following)
        }
        
        let isPending = mastodonUser.followRequestedBy.flatMap { $0.contains(currentMastodonUser) } ?? false
        if isPending {
            relationshipActionSet.insert(.pending)
        }
        
        let isBlocking = mastodonUser.blockingBy.flatMap { $0.contains(currentMastodonUser) } ?? false
        if isBlocking {
            relationshipActionSet.insert(.blocking)
        }
        
        let isBlockedBy = currentMastodonUser.blockingBy.flatMap { $0.contains(mastodonUser) } ?? false
        if isBlockedBy {
            relationshipActionSet.insert(.blocked)
        }
        return relationshipActionSet
    }

}
    
extension RecommendAccountSection {

    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        managedObjectContext: NSManagedObjectContext,
        viewModel: SuggestionAccountViewModel,
        delegate: SuggestionAccountTableViewCellDelegate
    ) -> UITableViewDiffableDataSource<RecommendAccountSection, NSManagedObjectID> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak viewModel, weak delegate] (tableView, indexPath, objectID) -> UITableViewCell? in
            guard let viewModel = viewModel else { return nil }
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SuggestionAccountTableViewCell.self)) as! SuggestionAccountTableViewCell
            let user = managedObjectContext.object(with: objectID) as! MastodonUser
            let isSelected = viewModel.selectedAccounts.value.contains(objectID)
            cell.delegate = delegate
            cell.config(with: user, isSelected: isSelected)
            return cell
        }
    }
}
