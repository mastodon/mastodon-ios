//
//  AutoCompleteViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-17.
//

import UIKit
import Combine
import GameplayKit
import MastodonSDK
import MastodonCore

@MainActor
public final class AutoCompleteViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    private(set) var authenticationBox: MastodonAuthenticationBox?
    public let inputText = CurrentValueSubject<String, Never>("")  // contains "@" or "#" prefix
    public let symbolBoundingRect = CurrentValueSubject<CGRect, Never>(.zero)
    public private(set) var customEmojiViewModel: EmojiService.CustomEmojiViewModel?
    
    // output
    public var autoCompleteItems = CurrentValueSubject<[AutoCompleteItem], Never>([])
    public var diffableDataSource: UITableViewDiffableDataSource<AutoCompleteSection, AutoCompleteItem>!
    private(set) lazy var stateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Loading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    /// No suggestions will be provided until an authentication box has been provided by calling setAuthenticationBox()
    public init() {
        authenticationBox = nil
        customEmojiViewModel = nil
    }
    
    public func setAuthenticationBox(_ authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = authenticationBox
        self.customEmojiViewModel = EmojiService.shared.dequeueCustomEmojiViewModel(for: authenticationBox.domain)
        
        prepareWithAuthenticationBox(authenticationBox)
    }
    
    private func prepareWithAuthenticationBox(_ authenticationBox: MastodonAuthenticationBox) {
        autoCompleteItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                var snapshot = NSDiffableDataSourceSnapshot<AutoCompleteSection, AutoCompleteItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items.removingDuplicates(), toSection: .main)
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Loading, is State.Fail:
                        if items.isEmpty {
                            snapshot.appendItems([.bottomLoader], toSection: .main)
                        }
                    case is State.Idle:
                        // TODO: handle no results
                        break
                    default:
                        break
                    }
                }
                
                diffableDataSource.defaultRowAnimation = .fade
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
        
        inputText
            .removeDuplicates()
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] inputText in
                guard let self = self else { return }
                self.stateMachine.enter(State.Loading.self)
            }
            .store(in: &disposeBag)
    }
    
    public init(authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = authenticationBox
        self.customEmojiViewModel = EmojiService.shared.dequeueCustomEmojiViewModel(for: authenticationBox.domain)
        // end init

        prepareWithAuthenticationBox(authenticationBox)
    }
    
}

extension AutoCompleteViewModel {
    enum SearchType {
        case accounts
        case hashtags
        case emoji
        case noSearch

        public var mastodonSearchType: Mastodon.API.V2.Search.SearchType? {
            switch self {
            case .accounts:     return .accounts
            case .hashtags:     return .hashtags
            case .emoji:        return nil
            case .noSearch:     return nil
            }
        }
        
        init(inputText: String) {
            let prefix = inputText.first ?? Character("_")
            switch prefix {
            case "@":   self = .accounts
            case "#":   self = .hashtags
            case ":":   self = .emoji
            default:    self = .noSearch
            }
        }
    }
}
