//
//  SearchViewController+Follow.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/4/9.
//

import Combine
import CoreDataStack
import Foundation
import UIKit

extension SearchViewController: UserProvider {
    
    func mastodonUser(for cell: UITableViewCell?) -> Future<MastodonUser?, Never> {
        return Future { promise in
            promise(.success(nil))
        }
    }
    
    func mastodonUser() -> Future<MastodonUser?, Never> {
        Future { promise in
            promise(.success(nil))
        }
    }
}

extension SearchViewController: SearchRecommendAccountsCollectionViewCellDelegate {
    func searchRecommendAccountsCollectionViewCell(_ cell: SearchRecommendAccountsCollectionViewCell, followButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.accountDiffableDataSource else { return }
        guard let indexPath = accountsCollectionView.indexPath(for: cell),
              let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        context.managedObjectContext.performAndWait {
            guard let user = try? context.managedObjectContext.existingObject(with: item) as? MastodonUser else { return }
            self.toggleFriendship(for: user)
        }
    }
    
    func toggleFriendship(for mastodonUser: MastodonUser) {
        guard let currentMastodonUser = viewModel.currentMastodonUser.value else {
            return
        }
        guard let relationshipAction = RecommendAccountSection.relationShipActionSet(
                mastodonUser: mastodonUser,
                currentMastodonUser: currentMastodonUser).highPriorityAction(except: .editOptions)
        else { return }
        switch relationshipAction {
        case .none:
            break
        case .follow, .following:
            UserProviderFacade.toggleUserFollowRelationship(provider: self, mastodonUser: mastodonUser)
                .sink { _ in
                    // error handling
                } receiveValue: { _ in
                    // success
                }
                .store(in: &disposeBag)
        case .pending:
            break
        case .muting:
            let name = mastodonUser.displayNameWithFallback
            let alertController = UIAlertController(
                title: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.title,
                message: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.message(name),
                preferredStyle: .alert
            )
            let unmuteAction = UIAlertAction(title: L10n.Common.Controls.Friendship.unmute, style: .default) { [weak self] _ in
                guard let self = self else { return }
                UserProviderFacade.toggleUserMuteRelationship(provider: self, mastodonUser: mastodonUser)
                    .sink { _ in
                        // do nothing
                    } receiveValue: { _ in
                        // do nothing
                    }
                    .store(in: &self.context.disposeBag)
            }
            alertController.addAction(unmuteAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        case .blocking:
            let name = mastodonUser.displayNameWithFallback
            let alertController = UIAlertController(
                title: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUsre.title,
                message: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUsre.message(name),
                preferredStyle: .alert
            )
            let unblockAction = UIAlertAction(title: L10n.Common.Controls.Friendship.unblock, style: .default) { [weak self] _ in
                guard let self = self else { return }
                UserProviderFacade.toggleUserBlockRelationship(provider: self, mastodonUser: mastodonUser)
                    .sink { _ in
                        // do nothing
                    } receiveValue: { _ in
                        // do nothing
                    }
                    .store(in: &self.context.disposeBag)
            }
            alertController.addAction(unblockAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        case .blocked:
            break
        default:
            assertionFailure()
        }
    }

}
