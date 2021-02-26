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

enum StatusProviderFacade {

}
extension StatusProviderFacade {
    
    static func responseToStatusLikeAction(provider: StatusProvider) {
        _responseToStatusLikeAction(
            provider: provider,
            toot: provider.toot()
        )
    }
    
    static func responseToStatusLikeAction(provider: StatusProvider, cell: UITableViewCell) {
        _responseToStatusLikeAction(
            provider: provider,
            toot: provider.toot(for: cell, indexPath: nil)
        )
    }
    
    private static func _responseToStatusLikeAction(provider: StatusProvider, toot: Future<Toot?, Never>) {
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
        
        toot
            .compactMap { toot -> (NSManagedObjectID, Mastodon.API.Favorites.FavoriteKind)? in
                guard let toot = toot else { return nil }
                let favoriteKind: Mastodon.API.Favorites.FavoriteKind = {
                    let targetToot = (toot.reblog ?? toot)
                    let isLiked = targetToot.favouritedBy.flatMap { $0.contains(where: { $0.id == mastodonUserID }) } ?? false
                    return isLiked ? .destroy : .create
                }()
                return (toot.objectID, favoriteKind)
            }
            .map { tootObjectID, favoriteKind -> AnyPublisher<(Toot.ID, Mastodon.API.Favorites.FavoriteKind), Error>  in
                return context.apiService.like(
                    tootObjectID: tootObjectID,
                    mastodonUserObjectID: mastodonUserObjectID,
                    favoriteKind: favoriteKind
                )
                .map { tootID in (tootID, favoriteKind) }
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
                os_log("%{public}s[%{public}ld], %{public}s: [Like] update local toot like status to: %s", ((#file as NSString).lastPathComponent), #line, #function, favoriteKind == .create ? "like" : "unlike")
            } receiveCompletion: { completion in
                switch completion {
                case .failure:
                    // TODO: handle error
                    break
                case .finished:
                    break
                }
            }
            .map { tootID, favoriteKind in
                return context.apiService.like(
                    statusID: tootID,
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
    enum Target {
        case toot
        case reblog
    }
}
 
