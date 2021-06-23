//
//  StatusProvider+StatusTableViewCellDelegate.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/8.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import ActiveLabel

// MARK: - StatusViewDelegate
extension StatusTableViewCellDelegate where Self: StatusProvider {

    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, headerInfoLabelDidPressed label: UILabel) {
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .secondary, provider: self, cell: cell)
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, avatarImageViewDidPressed imageView: UIImageView) {
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .primary, provider: self, cell: cell)
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        StatusProviderFacade.responseToStatusActiveLabelAction(provider: self, cell: cell, activeLabel: activeLabel, didTapEntity: entity)
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton) {
        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
    }
    
}

// MARK: - ActionToolbarContainerDelegate
extension StatusTableViewCellDelegate where Self: StatusProvider {
    
    func statusTableViewCell(_ cell: StatusTableViewCell, actionToolbarContainer: ActionToolbarContainer, replyButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusReplyAction(provider: self, cell: cell)
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, actionToolbarContainer: ActionToolbarContainer, reblogButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusReblogAction(provider: self, cell: cell)
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, actionToolbarContainer: ActionToolbarContainer, likeButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusLikeAction(provider: self, cell: cell)
    }
    
}

// MARK: - MosciaImageViewContainerDelegate
extension StatusTableViewCellDelegate where Self: StatusProvider {
    

    func statusTableViewCell(_ cell: StatusTableViewCell, mosaicImageViewContainer: MosaicImageViewContainer, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, cell: cell)
    }
    
}

extension StatusTableViewCellDelegate where Self: StatusProvider & MediaPreviewableViewController {
    func statusTableViewCell(_ cell: StatusTableViewCell, mosaicImageViewContainer: MosaicImageViewContainer, didTapImageView imageView: UIImageView, atIndex index: Int) {
        if UIAccessibility.isVoiceOverRunning, !(self is ThreadViewController) {
            StatusProviderFacade.coordinateToStatusThreadScene(for: .primary, provider: self, cell: cell)
        } else {
            StatusProviderFacade.coordinateToStatusMediaPreviewScene(provider: self, cell: cell, mosaicImageView: mosaicImageViewContainer, didTapImageView: imageView, atIndex: index)
        }
    }
}

// MARK: - PollTableView
extension StatusTableViewCellDelegate where Self: StatusProvider {
    
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, pollVoteButtonPressed button: UIButton) {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        status(for: cell, indexPath: nil)
            .receive(on: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .compactMap { status -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Poll>, Error>? in
                guard let status = (status?.reblog ?? status) else { return nil }
                guard let poll = status.poll else { return nil }
                
                let votedOptions = poll.options.filter { ($0.votedBy ?? Set()).contains(where: { $0.id == activeMastodonAuthenticationBox.userID }) }
                let choices = votedOptions.map { $0.index.intValue }
                let domain = poll.status.domain
                
                button.isEnabled = false
                
                return self.context.apiService.vote(
                    domain: domain,
                    pollID: poll.id,
                    pollObjectID: poll.objectID,
                    choices: choices,
                    mastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
            }
            .switchToLatest()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    // TODO: handle error
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: multiple vote fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    button.isEnabled = true
                case .finished:
                    break
                }
            }, receiveValue: { response in
                // do nothing
            })
            .store(in: &context.disposeBag)
    }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, pollTableView: PollTableView, didSelectRowAt indexPath: IndexPath) {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        guard let activeMastodonAuthentication = context.authenticationService.activeMastodonAuthentication.value else { return }
        
        guard let diffableDataSource = cell.statusView.pollTableViewDataSource else { return }
        let item = diffableDataSource.itemIdentifier(for: indexPath)
        guard case let .opion(objectID, _) = item else { return }
        guard let option = managedObjectContext.object(with: objectID) as? PollOption else { return }
        
        let poll = option.poll
        let pollObjectID = option.poll.objectID
        let domain = poll.status.domain
        
        if poll.multiple {
            var votedOptions = poll.options.filter { ($0.votedBy ?? Set()).contains(where: { $0.id == activeMastodonAuthenticationBox.userID }) }
            if votedOptions.contains(option) {
                votedOptions.remove(option)
            } else {
                votedOptions.insert(option)
            }
            let choices = votedOptions.map { $0.index.intValue }
            context.apiService.vote(
                pollObjectID: option.poll.objectID,
                mastodonUserObjectID: activeMastodonAuthentication.user.objectID,
                choices: choices
            )
            .handleEvents(receiveOutput: { _ in
                // TODO: add haptic
            })
            .receive(on: DispatchQueue.main)
            .sink { completion in
                // Do nothing
            } receiveValue: { _ in
                // Do nothing
            }
            .store(in: &context.disposeBag)
        } else {
            let choices = [option.index.intValue]
            context.apiService.vote(
                pollObjectID: pollObjectID,
                mastodonUserObjectID: activeMastodonAuthentication.user.objectID,
                choices: [option.index.intValue]
            )
            .handleEvents(receiveOutput: { _ in
                // TODO: add haptic
            })
            .flatMap { pollID -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Poll>, Error> in
                return self.context.apiService.vote(
                    domain: domain,
                    pollID: pollID,
                    pollObjectID: pollObjectID,
                    choices: choices,
                    mastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { response in
                print(response.value)
            }
            .store(in: &context.disposeBag)
        }
    }
    
}
