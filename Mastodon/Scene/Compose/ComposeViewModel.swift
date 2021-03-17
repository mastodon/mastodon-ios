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

final class ComposeViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let composeKind: ComposeStatusSection.ComposeKind
    let composeStatusAttribute = ComposeStatusItem.ComposeStatusAttribute()
    let composeContent = CurrentValueSubject<String, Never>("")
    let activeAuthentication: CurrentValueSubject<MastodonAuthentication?, Never>
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem>!
    
    // UI & UX
    let title: CurrentValueSubject<String, Never>
    let shouldDismiss = CurrentValueSubject<Bool, Never>(true)
    let isComposeTootBarButtonItemEnabled = CurrentValueSubject<Bool, Never>(false)
    
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
        // end init
        
        // bind active authentication
        context.authenticationService.activeMastodonAuthentication
            .assign(to: \.value, on: activeAuthentication)
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
        composeStatusAttribute.composeContent
            .receive(on: DispatchQueue.main)
            .map { content in
                let content = content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return !content.isEmpty
            }
            .assign(to: \.value, on: isComposeTootBarButtonItemEnabled)
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
