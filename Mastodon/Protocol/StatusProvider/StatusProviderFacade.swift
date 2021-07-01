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
import Meta
import MetaTextView

#if ASDK
import AsyncDisplayKit
#endif

enum StatusProviderFacade { }

extension StatusProviderFacade {
    
    static func coordinateToStatusAuthorProfileScene(for target: Target, provider: StatusProvider) {
        _coordinateToStatusAuthorProfileScene(
            for: target,
            provider: provider,
            status: provider.status()
        )
    }
    
    static func coordinateToStatusAuthorProfileScene(for target: Target, provider: StatusProvider, indexPath: IndexPath) {
        _coordinateToStatusAuthorProfileScene(
            for: target,
            provider: provider,
            status: provider.status(for: nil, indexPath: indexPath)
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
    
    static func coordinateToStatusThreadScene(for target: Target, provider: StatusProvider, indexPath: IndexPath) {
        _coordinateToStatusThreadScene(
            for: target,
            provider: provider,
            status: provider.status(for: nil, indexPath: indexPath)
        )
    }
    
    static func coordinateToStatusThreadScene(for target: Target, provider: StatusProvider, cell: UITableViewCell) {
        _coordinateToStatusThreadScene(
            for: target,
            provider: provider,
            status: provider.status(for: cell, indexPath: nil)
        )
    }
    
    private static func _coordinateToStatusThreadScene(for target: Target, provider: StatusProvider, status: Future<Status?, Never>) {
        status
            .sink { [weak provider] status in
                guard let provider = provider else { return }
                let _status: Status? = {
                    switch target {
                    case .primary:      return status?.reblog ?? status         // original status
                    case .secondary:    return status                           // reblog or status
                    }
                }()
                guard let status = _status else { return }
                
                let threadViewModel = CachedThreadViewModel(context: provider.context, status: status)
                DispatchQueue.main.async {
                    if provider.navigationController == nil {
                        let from = provider.presentingViewController ?? provider
                        provider.dismiss(animated: true) {
                            provider.coordinator.present(scene: .thread(viewModel: threadViewModel), from: from, transition: .show)
                        }
                    } else {
                        provider.coordinator.present(scene: .thread(viewModel: threadViewModel), from: provider, transition: .show)
                    }
                }
            }
            .store(in: &provider.disposeBag)
    }
    
}

extension StatusProviderFacade {
    
    static func responseToStatusActiveLabelAction(provider: StatusProvider, cell: UITableViewCell, activeLabel: ActiveLabel, didTapEntity entity: ActiveEntity) {
        switch entity.type {
        case .hashtag(let text, _):
            let hashtagTimelienViewModel = HashtagTimelineViewModel(context: provider.context, hashtag: text)
            provider.coordinator.present(scene: .hashtagTimeline(viewModel: hashtagTimelienViewModel), from: provider, transition: .show)
        case .mention(let text, _):
            coordinateToStatusMentionProfileScene(for: .primary, provider: provider, cell: cell, mention: text)
        case .url(_, _, let url, _):
            guard let url = URL(string: url) else { return }
            if let domain = provider.context.authenticationService.activeMastodonAuthenticationBox.value?.domain, url.host == domain,
               url.pathComponents.count >= 4,
               url.pathComponents[0] == "/",
               url.pathComponents[1] == "web",
               url.pathComponents[2] == "statuses" {
                let statusID = url.pathComponents[3]
                let threadViewModel = RemoteThreadViewModel(context: provider.context, statusID: statusID)
                provider.coordinator.present(scene: .thread(viewModel: threadViewModel), from: nil, transition: .show)
            } else {
                provider.coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
            }
        default:
            break
        }
    }

    static func responseToStatusMetaTextAction(provider: StatusProvider, cell: UITableViewCell, metaText: MetaText, didSelectMeta meta: Meta) {
        switch meta {
        case .url(_, _, let url, _):
            guard let url = URL(string: url) else { return }
            if let domain = provider.context.authenticationService.activeMastodonAuthenticationBox.value?.domain, url.host == domain,
               url.pathComponents.count >= 4,
               url.pathComponents[0] == "/",
               url.pathComponents[1] == "web",
               url.pathComponents[2] == "statuses" {
                let statusID = url.pathComponents[3]
                let threadViewModel = RemoteThreadViewModel(context: provider.context, statusID: statusID)
                provider.coordinator.present(scene: .thread(viewModel: threadViewModel), from: nil, transition: .show)
            } else {
                provider.coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
            }
        case .hashtag(_, let hashtag, _):
            let hashtagTimelineViewModel = HashtagTimelineViewModel(context: provider.context, hashtag: hashtag)
            provider.coordinator.present(scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel), from: provider, transition: .show)
        case .mention(_, let mention, _):
            coordinateToStatusMentionProfileScene(for: .primary, provider: provider, cell: cell, mention: mention)
        default:
            break
        }
    }

    #if ASDK
    static func responseToStatusActiveLabelAction(provider: StatusProvider, node: ASCellNode, didSelectActiveEntityType type: ActiveEntityType) {
        switch type {
        case .hashtag(let text, _):
            let hashtagTimelienViewModel = HashtagTimelineViewModel(context: provider.context, hashtag: text)
            provider.coordinator.present(scene: .hashtagTimeline(viewModel: hashtagTimelienViewModel), from: provider, transition: .show)
        case .mention(let text, _):
            coordinateToStatusMentionProfileScene(for: .primary, provider: provider, node: node, mention: text)
        case .url(_, _, let url, _):
            guard let url = URL(string: url) else { return }
            if let domain = provider.context.authenticationService.activeMastodonAuthenticationBox.value?.domain, url.host == domain,
               url.pathComponents.count >= 4,
               url.pathComponents[0] == "/",
               url.pathComponents[1] == "web",
               url.pathComponents[2] == "statuses" {
                let statusID = url.pathComponents[3]
                let threadViewModel = RemoteThreadViewModel(context: provider.context, statusID: statusID)
                provider.coordinator.present(scene: .thread(viewModel: threadViewModel), from: nil, transition: .show)
            } else {
                provider.coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
            }
        default:
            break
        }
    }

    private static func coordinateToStatusMentionProfileScene(for target: Target, provider: StatusProvider, node: ASCellNode, mention: String) {
        guard let status = provider.status(node: node, indexPath: nil) else { return }
        coordinateToStatusMentionProfileScene(for: target, provider: provider, status: status, mention: mention)
    }
    #endif

    private static func coordinateToStatusMentionProfileScene(for target: Target, provider: StatusProvider, cell: UITableViewCell, mention: String) {
        provider.status(for: cell, indexPath: nil)
            .sink { [weak provider] status in
                guard let provider = provider else { return }
                guard let status = status else { return }
                coordinateToStatusMentionProfileScene(for: target, provider: provider, status: status, mention: mention)
            }
            .store(in: &provider.disposeBag)
    }
    
    private static func coordinateToStatusMentionProfileScene(for target: Target, provider: StatusProvider, status: Status, mention: String) {
        guard let activeMastodonAuthenticationBox = provider.context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        let domain = activeMastodonAuthenticationBox.domain

        let status: Status = {
            switch target {
            case .primary:    return status.reblog ?? status
            case .secondary:  return status
            }
        }()

        // cannot continue without meta
        guard let mentionMeta = (status.mentions ?? Set()).first(where: { $0.username == mention }) else { return }

        let userID = mentionMeta.id

        let profileViewModel: ProfileViewModel = {
            // check if self
            guard userID != activeMastodonAuthenticationBox.userID else {
                return MeProfileViewModel(context: provider.context)
            }

            let request = MastodonUser.sortedFetchRequest
            request.fetchLimit = 1
            request.predicate = MastodonUser.predicate(domain: domain, id: userID)
            let mastodonUser = provider.context.managedObjectContext.safeFetch(request).first

            if let mastodonUser = mastodonUser {
                return CachedProfileViewModel(context: provider.context, mastodonUser: mastodonUser)
            } else {
                return RemoteProfileViewModel(context: provider.context, userID: userID)
            }
        }()

        DispatchQueue.main.async {
            provider.coordinator.present(scene: .profile(viewModel: profileViewModel), from: provider, transition: .show)
        }
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
    
    static func responseToStatusLikeAction(provider: StatusProvider, indexPath: IndexPath) {
        _responseToStatusLikeAction(
            provider: provider,
            status: provider.status(for: nil, indexPath: indexPath)
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
                return context.apiService.favorite(
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
                return context.apiService.favorite(
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
    
    static func responseToStatusReblogAction(provider: StatusProvider, indexPath: IndexPath) {
        _responseToStatusReblogAction(
            provider: provider,
            status: provider.status(for: nil, indexPath: indexPath)
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
    
    static func responseToStatusReplyAction(provider: StatusProvider) {
        _responseToStatusReplyAction(
            provider: provider,
            status: provider.status()
        )
    }
    
    static func responseToStatusReplyAction(provider: StatusProvider, cell: UITableViewCell) {
        _responseToStatusReplyAction(
            provider: provider,
            status: provider.status(for: cell, indexPath: nil)
        )
    }
    
    static func responseToStatusReplyAction(provider: StatusProvider, indexPath: IndexPath) {
        _responseToStatusReplyAction(
            provider: provider,
            status: provider.status(for: nil, indexPath: indexPath)
        )
    }
    
    private static func _responseToStatusReplyAction(provider: StatusProvider, status: Future<Status?, Never>) {
        status
            .sink { [weak provider] status in
                guard let provider = provider else { return }
                guard let status = status?.reblog ?? status else { return }
                
                let composeViewModel = ComposeViewModel(context: provider.context, composeKind: .reply(repliedToStatusObjectID: status.objectID))
                provider.coordinator.present(scene: .compose(viewModel: composeViewModel), from: provider, transition: .modal(animated: true, completion: nil))
            }
            .store(in: &provider.context.disposeBag)
        
    }
    
}

extension StatusProviderFacade {
    
    static func responseToStatusContentWarningRevealAction(provider: StatusProvider, cell: UITableViewCell) {
        _responseToStatusContentWarningRevealAction(
            dependency: provider,
            status: provider.status(for: cell, indexPath: nil)
        )
    }
    
    static func responseToStatusContentWarningRevealAction(provider: StatusProvider, indexPath: IndexPath) {
        _responseToStatusContentWarningRevealAction(
            dependency: provider,
            status: provider.status(for: nil, indexPath: indexPath)
        )
    }
    
    private static func _responseToStatusContentWarningRevealAction(dependency: NeedsDependency, status: Future<Status?, Never>) {
        status
            .compactMap { [weak dependency] status -> AnyPublisher<Status?, Never>? in
                guard let dependency = dependency else { return nil }
                guard let _status = status else { return nil }
                let managedObjectContext = dependency.context.backgroundManagedObjectContext
                return managedObjectContext.performChanges {
                    guard let status = managedObjectContext.object(with: _status.objectID) as? Status else { return }
                    let appStartUpTimestamp = dependency.context.documentStore.appStartUpTimestamp
                    let isRevealing: Bool = {
                        if dependency.context.documentStore.defaultRevealStatusDict[status.id] == true {
                            return true
                        }
                        if status.reblog.flatMap({ dependency.context.documentStore.defaultRevealStatusDict[$0.id] }) == true {
                            return true
                        }
                        if let revealedAt = status.revealedAt, revealedAt > appStartUpTimestamp {
                            return true
                        }
                        
                        return false
                    }()
                    // toggle reveal
                    dependency.context.documentStore.defaultRevealStatusDict[status.id] = false
                    status.update(isReveal: !isRevealing)

                    if let reblog = status.reblog {
                        dependency.context.documentStore.defaultRevealStatusDict[reblog.id] = false
                        reblog.update(isReveal: !isRevealing)
                    }
                    
                    // pause video playback if isRevealing before toggle
                    if isRevealing, let attachment = (status.reblog ?? status).mediaAttachments?.first,
                       let playerViewModel = dependency.context.videoPlaybackService.dequeueVideoPlayerViewModel(for: attachment) {
                        playerViewModel.pause()
                    }
                    // resume GIF playback if NOT isRevealing before toggle
                    if !isRevealing, let attachment = (status.reblog ?? status).mediaAttachments?.first,
                       let playerViewModel = dependency.context.videoPlaybackService.dequeueVideoPlayerViewModel(for: attachment), playerViewModel.videoKind == .gif {
                        playerViewModel.play()
                    }
                }
                .map { result in
                    return status
                }
                .eraseToAnyPublisher()
            }
            .sink { _ in
                // do nothing
            }
            .store(in: &dependency.context.disposeBag)
    }
    
    static func responseToStatusContentWarningRevealAction(dependency: ReportViewController, cell: UITableViewCell) {
        let status = Future<Status?, Never> { promise in
            guard let diffableDataSource = dependency.viewModel.diffableDataSource,
                  let indexPath = dependency.tableView.indexPath(for: cell),
                  let item = diffableDataSource.itemIdentifier(for: indexPath) else {
                promise(.success(nil))
                return
            }
            let managedObjectContext = dependency.viewModel.statusFetchedResultsController
                .fetchedResultsController
                .managedObjectContext
            
            switch item {
            case .reportStatus(let objectID, _):
                managedObjectContext.perform {
                    let status = managedObjectContext.object(with: objectID) as! Status
                    promise(.success(status))
                }
            default:
                promise(.success(nil))
            }
        }
        
        _responseToStatusContentWarningRevealAction(
            dependency: dependency,
            status: status
        )
    }
}

extension StatusProviderFacade {
    static func coordinateToStatusMediaPreviewScene(provider: StatusProvider & MediaPreviewableViewController, cell: UITableViewCell, mosaicImageView: MosaicImageViewContainer, didTapImageView imageView: UIImageView, atIndex index: Int) {
        provider.status(for: cell, indexPath: nil)
            .sink { [weak provider] status in
                guard let provider = provider else { return }
                guard let source = status else { return }
                
                let status = source.reblog ?? source
                
                let meta = MediaPreviewViewModel.StatusImagePreviewMeta(
                    statusObjectID: status.objectID,
                    initialIndex: index,
                    preloadThumbnailImages: mosaicImageView.thumbnails()
                )
                let pushTransitionItem = MediaPreviewTransitionItem(
                    source: .mosaic(mosaicImageView),
                    previewableViewController: provider
                )
                pushTransitionItem.aspectRatio = {
                    if let image = imageView.image {
                        return image.size
                    }
                    guard let media = status.mediaAttachments?.sorted(by: { $0.index.compare($1.index) == .orderedAscending }) else { return nil }
                    guard index < media.count else { return nil }
                    let meta = media[index].meta
                    guard let width = meta?.original?.width, let height = meta?.original?.height else { return nil }
                    return CGSize(width: width, height: height)
                }()
                pushTransitionItem.sourceImageView = imageView
                pushTransitionItem.initialFrame = {
                    let initialFrame = imageView.superview!.convert(imageView.frame, to: nil)
                    assert(initialFrame != .zero)
                    return initialFrame
                }()
                pushTransitionItem.image = {
                    if let image = imageView.image {
                        return image
                    }
                    if index < mosaicImageView.blurhashOverlayImageViews.count {
                        return mosaicImageView.blurhashOverlayImageViews[index].image
                    }
                    
                    return nil 
                }()
                
                let mediaPreviewViewModel = MediaPreviewViewModel(
                    context: provider.context,
                    meta: meta,
                    pushTransitionItem: pushTransitionItem
                )
                DispatchQueue.main.async {
                    provider.coordinator.present(scene: .mediaPreview(viewModel: mediaPreviewViewModel), from: provider, transition: .custom(transitioningDelegate: provider.mediaPreviewTransitionController))
                }
            }
            .store(in: &provider.disposeBag)
    }
}

extension StatusProviderFacade {
    enum Target {
        case primary        // original status
        case secondary      // wrapper status or reply (when needs. e.g tap header of status view)
    }
}
 
