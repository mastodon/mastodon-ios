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
import MastodonCore

extension AutoCompleteViewModel {
    class State: GKState {
        
        let logger = Logger(subsystem: "AutoCompleteViewModel.State", category: "StateMachine")
        
        let id = UUID()

        weak var viewModel: AutoCompleteViewModel?
        
        init(viewModel: AutoCompleteViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            let from = previousState.flatMap { String(describing: $0) } ?? "nil"
            let to = String(describing: self)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(from) -> \(to)")
        }
        
        @MainActor
        func enter(state: State.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(String(describing: self))")
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
            guard let viewModel = viewModel, let _ = stateMachine else { return }

            let searchText = viewModel.inputText.value
            let searchType = AutoCompleteViewModel.SearchType(inputText: searchText) ?? .default
            if searchText != previoursSearchText {
                reset(searchText: searchText)
            }
            
            switch searchType {
            case .emoji:
                Task {
                    await fetchLocalEmoji(searchText: searchText)
                }
            default:
                Task {
                    await queryRemoteEnitity(searchText: searchText)
                }
            }
        }
        
        private func fetchLocalEmoji(searchText: String) async {
            guard let viewModel = viewModel else {
                await enter(state: Fail.self)
                return
            }
            
            guard let customEmojiViewModel = viewModel.customEmojiViewModel else {
                await enter(state: Fail.self)
                return
            }
            
            guard let emojiTrie = customEmojiViewModel.emojiTrie.value else {
                await enter(state: Fail.self)
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

            await enter(state: Idle.self)
            viewModel.autoCompleteItems.value = items
        }
        
        private func queryRemoteEnitity(searchText: String) async {
            guard let viewModel = viewModel else {
                await enter(state: Fail.self)
                return
            }

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
            
            do {
                let response = try await viewModel.context.apiService.search(
                    query: query,
                    authenticationBox: viewModel.authContext.mastodonAuthenticationBox
                )
                
                await enter(state: Idle.self)

                guard viewModel.inputText.value == searchText else { return }     // discard if not matching
                
                var items: [AutoCompleteItem] = []
                items.append(contentsOf: response.value.accounts.map { AutoCompleteItem.account(account: $0) })
                items.append(contentsOf: response.value.hashtags.map { AutoCompleteItem.hashtag(tag: $0) })

                viewModel.autoCompleteItems.value = items
                
            } catch {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): auto-complete fail: \(error.localizedDescription)")
                await enter(state: Fail.self)
            }
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
