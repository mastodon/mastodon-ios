//
//  StatusProviderFacade.swift
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

enum StatusProviderFacade { }

extension StatusProviderFacade {
    
    static func coordinateToStatusAuthorProfileScene(for target: Target, provider: StatusProvider) {
        _coordinateToStatusAuthorProfileScene(
            for: target,
            provider: provider,
            status: provider.status()
        )
    }
    
    static func coordinateToStatusAuthorProfileScene(for target: Target, provider: StatusProvider, cell: UITableViewCell) {
        _coordinateToStatusAuthorProfileScene(
            for: target,
            provider: provider,
            status: provider.status(for: cell, indexPath: nil)
        )
    }
    
    private static func _coordinateToStatusAuthorProfileScene(for target: Target, provider: StatusProvider, status: Future<Status?, Never>) {
        status
            .sink { [weak provider] status in
                guard let provider = provider else { return }
                let _status: Status? = {
                    switch target {
                    case .primary:      return status?.reblog ?? status         // original status
                    case .secondary:    return status?.replyTo ?? status        // reblog or reply to status
                    }
                }()
                guard let status = _status else { return }
                
                let mastodonUser = status.author
                let profileViewModel = CachedProfileViewModel(context: provider.context, mastodonUser: mastodonUser)
                DispatchQueue.main.async {
                    if provider.navigationController == nil {
                        let from = provider.presentingViewController ?? provider
                        provider.dismiss(animated: true) {
                            provider.coordinator.present(scene: .profile(viewModel: profileViewModel), from: from, transition: .show)
                        }
                    } else {
                        provider.coordinator.present(scene: .profile(viewModel: profileViewModel), from: provider, transition: .show)
                    }
                }
            }
            .store(in: &provider.disposeBag)
    }
}

extension StatusProviderFacade {
    
    static func responseToStatusLikeAction(provider: StatusProvider) {
        _responseToStatusLikeAction(
            provider: provider,
            status: provider.status()
        )
    }
    
    static func responseToStatusLikeAction(provider: StatusProvider, cell: UITableViewCell) {
        _responseToStatusLikeAction(
            provider: provider,
            status: provider.status(for: cell, indexPath: nil)
        )
    }
    
    private static func _responseToStatusLikeAction(provider: StatusProvider, status: Future<Status?, Never>) {
        // prepare authentication
        guard let activeMastodonAuthenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else {
            assertionFailure()
            return
        }
        
        // prepare current user infos
        guard let _currentMastodonUser = provider.context.authenticationService.activeMastodonAuthentication.value?.user else {
            assertionFailure()
            return
        }
        let mastodonUserID = activeMastodonAuthenticationBox.userID
        assert(_currentMastodonUser.id == mastodonUserID)
        let mastodonUserObjectID = _currentMastodonUser.objectID
        
        guard let context = provider.context else { return }
        
        // haptic feedback generator
        let generator = UIImpactFeedbackGenerator(style: .light)
        let responseFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        
        status
            .compactMap { status -> (NSManagedObjectID, Mastodon.API.Favorites.FavoriteKind)? in
                guard let status = status?.reblog ?? status else { return nil }
                let favoriteKind: Mastodon.API.Favorites.FavoriteKind = {
                    let isLiked = status.favouritedBy.flatMap { $0.contains(where: { $0.id == mastodonUserID }) } ?? false
                    return isLiked ? .destroy : .create
                }()
                return (status.objectID, favoriteKind)
            }
            .map { statusObjectID, favoriteKind -> AnyPublisher<(Status.ID, Mastodon.API.Favorites.FavoriteKind), Error>  in
                return context.apiService.like(
                            statusObjectID: statusObjectID,
                    mastodonUserObjectID: mastodonUserObjectID,
                    favoriteKind: favoriteKind
                )
                .map { statusID in (statusID, favoriteKind) }
                .eraseToAnyPublisher()
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .handleEvents { _ in
                generator.prepare()
                responseFeedbackGenerator.prepare()
            } receiveOutput: { _, favoriteKind in
                generator.impactOccurred()
                os_log("%{public}s[%{public}ld], %{public}s: [Like] update local status like status to: %s", ((#file as NSString).lastPathComponent), #line, #function, favoriteKind == .create ? "like" : "unlike")
            } receiveCompletion: { completion in
                switch completion {
                case .failure:
                    // TODO: handle error
                    break
                case .finished:
                    break
                }
            }
            .map { statusID, favoriteKind in
                return context.apiService.like(
                    statusID: statusID,
                    favoriteKind: favoriteKind,
                    mastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak provider] completion in
                guard let provider = provider else { return }
                if provider.view.window != nil {
                    responseFeedbackGenerator.impactOccurred()
                }
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: [Like] remote like request fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                case .finished:
                    os_log("%{public}s[%{public}ld], %{public}s: [Like] remote like request success", ((#file as NSString).lastPathComponent), #line, #function)
                }
            } receiveValue: { response in
                // do nothing
            }
            .store(in: &provider.disposeBag)
    }
    
}

extension StatusProviderFacade {
 
    
    static func responseToStatusReblogAction(provider: StatusProvider) {
        _responseToStatusReblogAction(
            provider: provider,
            status: provider.status()
        )
    }
    
    static func responseToStatusReblogAction(provider: StatusProvider, cell: UITableViewCell) {
        _responseToStatusReblogAction(
            provider: provider,
            status: provider.status(for: cell, indexPath: nil)
        )
    }
    
    private static func _responseToStatusReblogAction(provider: StatusProvider, status: Future<Status?, Never>) {
        // prepare authentication
        guard let activeMastodonAuthenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else {
            assertionFailure()
            return
        }
        
        // prepare current user infos
        guard let _currentMastodonUser = provider.context.authenticationService.activeMastodonAuthentication.value?.user else {
            assertionFailure()
            return
        }
        let mastodonUserID = activeMastodonAuthenticationBox.userID
        assert(_currentMastodonUser.id == mastodonUserID)
        let mastodonUserObjectID = _currentMastodonUser.objectID
        
        guard let context = provider.context else { return }
        
        // haptic feedback generator
        let generator = UIImpactFeedbackGenerator(style: .light)
        let responseFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        
        status
            .compactMap { status -> (NSManagedObjectID, Mastodon.API.Reblog.ReblogKind)? in
                guard let status = status?.reblog ?? status else { return nil }
                let reblogKind: Mastodon.API.Reblog.ReblogKind = {
                    let isReblogged = status.rebloggedBy.flatMap { $0.contains(where: { $0.id == mastodonUserID }) } ?? false
                    return isReblogged ? .undoReblog : .reblog(query: .init(visibility: nil))
                }()
                return (status.objectID, reblogKind)
            }
            .map { statusObjectID, reblogKind -> AnyPublisher<(Status.ID, Mastodon.API.Reblog.ReblogKind), Error>  in
                return context.apiService.reblog(
                    statusObjectID: statusObjectID,
                    mastodonUserObjectID: mastodonUserObjectID,
                    reblogKind: reblogKind
                )
                .map { statusID in (statusID, reblogKind) }
                .eraseToAnyPublisher()
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .handleEvents { _ in
                generator.prepare()
                responseFeedbackGenerator.prepare()
            } receiveOutput: { _, reblogKind in
                generator.impactOccurred()
                switch reblogKind {
                case .reblog:
                    os_log("%{public}s[%{public}ld], %{public}s: [Reblog] update local status reblog status to: %s", ((#file as NSString).lastPathComponent), #line, #function, "reblog")
                case .undoReblog:
                    os_log("%{public}s[%{public}ld], %{public}s: [Reblog] update local status reblog status to: %s", ((#file as NSString).lastPathComponent), #line, #function, "unreblog")
                }
            } receiveCompletion: { completion in
                switch completion {
                case .failure:
                    // TODO: handle error
                    break
                case .finished:
                    break
                }
            }
            .map { statusID, reblogKind in
                return context.apiService.reblog(
                    statusID: statusID,
                    reblogKind: reblogKind,
                    mastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak provider] completion in
                guard let provider = provider else { return }
                if provider.view.window != nil {
                    responseFeedbackGenerator.impactOccurred()
                }
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: [Reblog] remote reblog request fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                case .finished:
                    os_log("%{public}s[%{public}ld], %{public}s: [Reblog] remote reblog request success", ((#file as NSString).lastPathComponent), #line, #function)
                }
            } receiveValue: { response in
                // do nothing
            }
            .store(in: &provider.disposeBag)
    }

}

extension StatusProviderFacade {
    enum Target {
        case primary        // original
        case secondary      // attachment reblog or reply
    }
}
 
