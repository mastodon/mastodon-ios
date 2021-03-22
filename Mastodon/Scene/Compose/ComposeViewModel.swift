//
//  ComposeViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit

final class ComposeViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let composeKind: ComposeStatusSection.ComposeKind
    let composeStatusAttribute = ComposeStatusItem.ComposeStatusAttribute()
    let activeAuthentication: CurrentValueSubject<MastodonAuthentication?, Never>
    let activeAuthenticationBox: CurrentValueSubject<AuthenticationService.MastodonAuthenticationBox?, Never>
    
    // output
    //var diffableDataSource: UITableViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem>!
    var diffableDataSource: UICollectionViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem>!
    private(set) lazy var publishStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            PublishState.Initial(viewModel: self),
            PublishState.Publishing(viewModel: self),
            PublishState.Fail(viewModel: self),
            PublishState.Finish(viewModel: self),
        ])
        stateMachine.enter(PublishState.Initial.self)
        return stateMachine
    }()
    
    // UI & UX
    let title: CurrentValueSubject<String, Never>
    let shouldDismiss = CurrentValueSubject<Bool, Never>(true)
    let isPublishBarButtonItemEnabled = CurrentValueSubject<Bool, Never>(false)
    
    // custom emojis
    let customEmojiViewModel = CurrentValueSubject<EmojiService.CustomEmojiViewModel?, Never>(nil)
    
    // attachment
    let attachmentServices = CurrentValueSubject<[MastodonAttachmentService], Never>([])
    
    init(
        context: AppContext,
        composeKind: ComposeStatusSection.ComposeKind
    ) {
        self.context = context
        self.composeKind = composeKind
        switch composeKind {
        case .post:         self.title = CurrentValueSubject(L10n.Scene.Compose.Title.newPost)
        case .reply:        self.title = CurrentValueSubject(L10n.Scene.Compose.Title.newReply)
        }
        self.activeAuthentication = CurrentValueSubject(context.authenticationService.activeMastodonAuthentication.value)
        self.activeAuthenticationBox = CurrentValueSubject(context.authenticationService.activeMastodonAuthenticationBox.value)
        // end init
        
        // bind active authentication
        context.authenticationService.activeMastodonAuthentication
            .assign(to: \.value, on: activeAuthentication)
            .store(in: &disposeBag)
        context.authenticationService.activeMastodonAuthenticationBox
            .assign(to: \.value, on: activeAuthenticationBox)
            .store(in: &disposeBag)
        
        // bind avatar and names
        activeAuthentication
            .sink { [weak self] mastodonAuthentication in
                guard let self = self else { return }
                let mastodonUser = mastodonAuthentication?.user
                let username = mastodonUser?.username ?? " "

                self.composeStatusAttribute.avatarURL.value = mastodonUser?.avatarImageURL()
                self.composeStatusAttribute.displayName.value = {
                    guard let displayName = mastodonUser?.displayName, !displayName.isEmpty else {
                        return username
                    }
                    return displayName
                }()
                self.composeStatusAttribute.username.value = username
            }
            .store(in: &disposeBag)
        
        // bind compose bar button item UI state
        let isComposeContentEmpty = composeStatusAttribute.composeContent
            .map { ($0 ?? "").isEmpty }
        let isComposeContentValid = Just(true).eraseToAnyPublisher()
        let isMediaEmpty = attachmentServices
            .map { $0.isEmpty }
        let isMediaUploadAllSuccess = attachmentServices
            .map { services in
                services.allSatisfy { $0.uploadStateMachineSubject.value is MastodonAttachmentService.UploadState.Finish }
            }
        Publishers.CombineLatest4(
            isComposeContentEmpty.eraseToAnyPublisher(),
            isComposeContentValid.eraseToAnyPublisher(),
            isMediaEmpty.eraseToAnyPublisher(),
            isMediaUploadAllSuccess.eraseToAnyPublisher()
        )
        .map { isComposeContentEmpty, isComposeContentValid, isMediaEmpty, isMediaUploadAllSuccess in
            if isMediaEmpty {
                return isComposeContentValid && !isComposeContentEmpty
            } else {
                return isComposeContentValid && isMediaUploadAllSuccess
            }
        }
        .assign(to: \.value, on: isPublishBarButtonItemEnabled)
        .store(in: &disposeBag)
        
        // bind modal dismiss state
        composeStatusAttribute.composeContent
            .receive(on: DispatchQueue.main)
            .map { content in
                let content = content ?? ""
                return content.isEmpty
            }
            .assign(to: \.value, on: shouldDismiss)
            .store(in: &disposeBag)
        
        // bind custom emojis
        context.authenticationService.activeMastodonAuthenticationBox
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeMastodonAuthenticationBox in
                guard let self = self else { return }
                guard let activeMastodonAuthenticationBox = activeMastodonAuthenticationBox else { return }
                let domain = activeMastodonAuthenticationBox.domain
                
                // trigger dequeue to preload emojis
                self.customEmojiViewModel.value = self.context.emojiService.dequeueCustomEmojiViewModel(for: domain)
            }
            .store(in: &disposeBag)
        
        // bind snapshot
        attachmentServices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] attachmentServices in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                var snapshot = diffableDataSource.snapshot()
                
                snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .attachment))
                var items: [ComposeStatusItem] = []
                for attachmentService in attachmentServices {
                    let item = ComposeStatusItem.attachment(attachmentService: attachmentService)
                    items.append(item)
                }
                snapshot.appendItems(items, toSection: .attachment)
                
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
    
}

// MARK: - MastodonAttachmentServiceDelegate
extension ComposeViewModel: MastodonAttachmentServiceDelegate {
    func mastodonAttachmentService(_ service: MastodonAttachmentService, uploadStateDidChange state: MastodonAttachmentService.UploadState?) {
        // trigger new output event
        attachmentServices.value = attachmentServices.value
    }
}
