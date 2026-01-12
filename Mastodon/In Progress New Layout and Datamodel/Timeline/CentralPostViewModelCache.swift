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
                for (key, weakWrapper) in _cache {
                    if let postModel = weakWrapper.value {
                        postModel.incorporateUpdate(update)
                    } else {
                        _cache.removeValue(forKey: key)
                    }
                }
            }
    }
    
    private struct WeakPostViewModel {
        weak var value: MastodonPostViewModel?
    }
    
    private var _cache = [ String : WeakPostViewModel ]()
    
    func cachedModel(for postID: Mastodon.Entity.Status.ID) -> MastodonPostViewModel? {
        return _cache[postID]?.value
    }
    
    func addToCache(_ model: MastodonPostViewModel) {
        let weakWrapper = WeakPostViewModel(value: model)
        _cache[model.initialDisplayInfo.id] = weakWrapper
    }
}
