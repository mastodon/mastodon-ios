//
//  EmojiService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-15.
//

import Foundation
import Combine
import MastodonSDK

public final class EmojiService {
    let apiService: APIService
    let authenticationService: AuthenticationService

    let workingQueue = DispatchQueue(label: "org.joinmastodon.app.EmojiService.working-queue")
    private(set) var customEmojiViewModelDict: [String: CustomEmojiViewModel] = [:]
    
    init(apiService: APIService, authenticationService: AuthenticationService) {
        self.apiService = apiService
        self.authenticationService = authenticationService
    }
    
}

extension EmojiService {

    public func dequeueCustomEmojiViewModel(for domain: String) -> CustomEmojiViewModel? {
        var _customEmojiViewModel: CustomEmojiViewModel?
        workingQueue.sync {
            if let viewModel = customEmojiViewModelDict[domain] {
                _customEmojiViewModel = viewModel
            } else {
                let viewModel = CustomEmojiViewModel(domain: domain, service: self)
                _customEmojiViewModel = viewModel
                
                // trigger loading
                viewModel.stateMachine.enter(CustomEmojiViewModel.LoadState.Loading.self)
            }
        }
        return _customEmojiViewModel
    }
    
}

