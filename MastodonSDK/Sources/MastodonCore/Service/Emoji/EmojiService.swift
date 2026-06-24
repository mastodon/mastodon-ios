//
//  EmojiService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-15.
//

import Foundation
import Combine
import MastodonSDK

@MainActor
public final class EmojiService {
    public static let shared = { EmojiService() }()
    let workingQueue = DispatchQueue(label: "org.joinmastodon.app.EmojiService.working-queue")
    private(set) var customEmojiViewModelDict: [String: CustomEmojiViewModel] = [:]
}

extension EmojiService {

    public func dequeueCustomEmojiViewModel(for domain: String) -> CustomEmojiViewModel? {
        var _customEmojiViewModel: CustomEmojiViewModel?
        workingQueue.sync {
            if let viewModel = customEmojiViewModelDict[domain] {
                _customEmojiViewModel = viewModel
            } else {
                let viewModel = CustomEmojiViewModel(domain: domain, service: self)
                customEmojiViewModelDict[domain] = viewModel
                _customEmojiViewModel = viewModel
                
                // trigger loading
                viewModel.stateMachine.enter(CustomEmojiViewModel.LoadState.Loading.self)
            }
        }
        return _customEmojiViewModel
    }
    
}

