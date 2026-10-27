// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Combine
import Foundation
import MastodonSDK

@MainActor
class CentralPostViewModelCache {
    
    static let shared = CentralPostViewModelCache()
    
    private var updateSubscription: AnyCancellable?
    
    private init() {
        self.updateSubscription = FeedCoordinator.shared.$mostRecentUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self, let update else { return }
                switch update {
                case .deletedPost:
                    return
                default:
                    break
                }
                incorporateUpdate(update)
            }
    }
    
    private struct WeakPostViewModel {
        weak var value: MastodonPostViewModel?
    }
    private struct CacheKey: Hashable {
        let postID: String
        let displayType: MastodonPostViewModel.DisplayType
    }
    private var _cache = [ CacheKey : WeakPostViewModel ]()
    
    func model(forPost post: GenericMastodonPost, displayType: MastodonPostViewModel.DisplayType = .standard) -> MastodonPostViewModel {
        let actionablePost = post.actionablePost ?? post
        incorporateUpdate(.post(actionablePost)) // any boosts or notifications will want to know about this potentially newer version of the post
        let initialDisplayInfo = post.initialDisplayInfo()
        let key = CacheKey(postID: initialDisplayInfo.id, displayType: displayType)
        if let existing = _cache[key]?.value {
            return existing
        } else {
            let model = MastodonPostViewModel(initialDisplayInfo, displayType: displayType)
            model.initialSetFullPost(post)
            _cache[key] = WeakPostViewModel(value: model)
            return model
        }
    }
    
    private func incorporateUpdate(_ update: UpdatedElement) {
        for (key, weakWrapper) in _cache {
            if let postModel = weakWrapper.value {
                postModel.incorporateUpdate(update)
            } else {
                _cache.removeValue(forKey: key)
            }
        }
    }
}
