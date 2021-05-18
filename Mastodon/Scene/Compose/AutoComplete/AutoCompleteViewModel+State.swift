//
//  AutoCompleteViewModel+State.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-17.
//

import os.log
import Foundation
import GameplayKit
import MastodonSDK

extension AutoCompleteViewModel {
    class State: GKState {
        weak var viewModel: AutoCompleteViewModel?
        
        init(viewModel: AutoCompleteViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension AutoCompleteViewModel.State {
    class Initial: AutoCompleteViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            switch stateClass {
            case is Loading.Type:
                return !viewModel.inputText.value.isEmpty
            default:
                return false
            }
        }
    }
    
    class Loading: AutoCompleteViewModel.State {
        
        var previoursSearchText = ""
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            switch stateClass {
            case is Loading.Type:
                return previoursSearchText != viewModel.inputText.value
            case is Fail.Type:
                return true
            case is Idle.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }

            let searchText = viewModel.inputText.value
            let searchType = AutoCompleteViewModel.SearchType(inputText: searchText) ?? .default
            if searchText != previoursSearchText {
                reset(searchText: searchText)
            }
            
            switch searchType {
            case .emoji:
                Loading.fetchLocalEmoji(
                    searchText: searchText,
                    viewModel: viewModel,
                    stateMachine: stateMachine
                )
            default:
                Loading.queryRemoteEnitity(
                    searchText: searchText,
                    viewModel: viewModel,
                    stateMachine: stateMachine
                )
            }
        }
        
        private static func fetchLocalEmoji(
            searchText: String,
            viewModel: AutoCompleteViewModel,
            stateMachine: GKStateMachine
        ) {
            guard let customEmojiViewModel = viewModel.customEmojiViewModel.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            guard let emojiTrie = customEmojiViewModel.emojiTrie.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            let searchPattern = ArraySlice(String(searchText.dropFirst()))
            let passthroughs = emojiTrie.passthrough(searchPattern)
            let matchingEmojis = passthroughs
                .map { $0.values }                                              // [Set<Emoji>]
                .map { set in set.compactMap { $0 as? Mastodon.Entity.Emoji } } // [[Emoji]]
                .flatMap { $0 }                                                 // [Emoji]
            let items: [AutoCompleteItem] = matchingEmojis.map { emoji in
                AutoCompleteItem.emoji(emoji: emoji)
            }
            stateMachine.enter(Idle.self)
            viewModel.autoCompleteItems.value = items
        }
        
        private static func queryRemoteEnitity(
            searchText: String,
            viewModel: AutoCompleteViewModel,
            stateMachine: GKStateMachine
        ) {
            guard let activeMastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            let domain = activeMastodonAuthenticationBox.domain

            let searchText = viewModel.inputText.value
            let searchType = AutoCompleteViewModel.SearchType(inputText: searchText) ?? .default
            
            let q = String(searchText.dropFirst())
            let query = Mastodon.API.V2.Search.Query(
                q: q,
                type: searchType.mastodonSearchType,
                maxID: nil,
                offset: nil,
                following: nil
            )
            viewModel.context.apiService.search(
                domain: domain,
                query: query,
                mastodonAuthenticationBox: activeMastodonAuthenticationBox
            )
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: auto-complete fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    stateMachine.enter(Fail.self)
                case .finished:
                    break
                }
            } receiveValue: { response in
                guard viewModel.inputText.value == searchText else { return }     // discard if not matching
                
                var items: [AutoCompleteItem] = []
                items.append(contentsOf: response.value.accounts.map { AutoCompleteItem.account(account: $0) })
                items.append(contentsOf: response.value.hashtags.map { AutoCompleteItem.hashtag(tag: $0) })
                stateMachine.enter(Idle.self)
                viewModel.autoCompleteItems.value = items
            }
            .store(in: &viewModel.disposeBag)
        }
        
        private func reset(searchText: String) {
            let previoursSearchType = AutoCompleteViewModel.SearchType(inputText: previoursSearchText)
            previoursSearchText = searchText
            let currentSearchType = AutoCompleteViewModel.SearchType(inputText: searchText)
            // reset when search type change
            if previoursSearchType != currentSearchType {
                viewModel?.autoCompleteItems.value = []
            }
        }
        
    }
    
    class Idle: AutoCompleteViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Fail: AutoCompleteViewModel.State {
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let _ = viewModel, let stateMachine = stateMachine else { return }
            
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading 3s later…", ((#file as NSString).lastPathComponent), #line, #function)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading", ((#file as NSString).lastPathComponent), #line, #function)
                stateMachine.enter(Loading.self)
            }
        }
    }

}
