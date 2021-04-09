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
    func mastodonUser() -> Future<MastodonUser?, Never> {
        Future { promise in
            promise(.success(self.viewModel.mastodonUser.value))
        }
    }
}

extension SearchViewController: SearchRecommendAccountsCollectionViewCellDelegate {
    func followButtonDidPressed(clickedUser: MastodonUser) {
        viewModel.mastodonUser.value = clickedUser
        guard let currentMastodonUser = viewModel.currentMastodonUser.value else {
            return
        }
        guard let relationshipAction = relationShipActionSet(mastodonUser: clickedUser, currentMastodonUser: currentMastodonUser).highPriorityAction(except: .editOptions) else { return }
        switch relationshipAction {
        case .none:
            break
        case .follow, .following:
            UserProviderFacade.toggleUserFollowRelationship(provider: self)
                .sink { _ in

                } receiveValue: { _ in
                }
                .store(in: &disposeBag)
        case .pending:
            break
        case .muting:
            guard let mastodonUser = viewModel.mastodonUser.value else { return }
            let name = mastodonUser.displayNameWithFallback
            let alertController = UIAlertController(
                title: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.title,
                message: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.message(name),
                preferredStyle: .alert
            )
            let unmuteAction = UIAlertAction(title: L10n.Common.Controls.Firendship.unmute, style: .default) { [weak self] _ in
                guard let self = self else { return }
                UserProviderFacade.toggleUserMuteRelationship(provider: self)
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
            guard let mastodonUser = viewModel.mastodonUser.value else { return }
            let name = mastodonUser.displayNameWithFallback
            let alertController = UIAlertController(
                title: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUsre.title,
                message: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUsre.message(name),
                preferredStyle: .alert
            )
            let unblockAction = UIAlertAction(title: L10n.Common.Controls.Firendship.unblock, style: .default) { [weak self] _ in
                guard let self = self else { return }
                UserProviderFacade.toggleUserBlockRelationship(provider: self)
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

    func configFollowButton(with mastodonUser: MastodonUser, followButton: HighlightDimmableButton) {
        guard let currentMastodonUser = viewModel.currentMastodonUser.value else {
            return
        }
        _configFollowButton(with: mastodonUser, currentMastodonUser: currentMastodonUser, followButton: followButton)
        ManagedObjectObserver.observe(object: currentMastodonUser)
            .sink { _ in

            } receiveValue: { change in
                guard case .update(let object) = change.changeType,
                      let newUser = object as? MastodonUser else { return }
                self._configFollowButton(with: mastodonUser, currentMastodonUser: newUser, followButton: followButton)
            }
            .store(in: &disposeBag)
    }
}

extension SearchViewController {
    func _configFollowButton(with mastodonUser: MastodonUser, currentMastodonUser: MastodonUser, followButton: HighlightDimmableButton) {
        let relationshipActionSet = relationShipActionSet(mastodonUser: mastodonUser, currentMastodonUser: currentMastodonUser)
        followButton.setTitle(relationshipActionSet.title, for: .normal)
    }

    func relationShipActionSet(mastodonUser: MastodonUser, currentMastodonUser: MastodonUser) -> ProfileViewModel.RelationshipActionOptionSet {
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
