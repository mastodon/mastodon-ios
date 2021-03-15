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
    let composeTootAttribute = ComposeStatusItem.ComposeTootAttribute()
    let composeContent = CurrentValueSubject<String, Never>("")
    let activeAuthentication: CurrentValueSubject<MastodonAuthentication?, Never>
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem>!
    
    // UI & UX
    let title: CurrentValueSubject<String, Never>
    let shouldDismiss = CurrentValueSubject<Bool, Never>(true)
    let isComposeTootBarButtonItemEnabled = CurrentValueSubject<Bool, Never>(false)
    
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
        
        activeAuthentication
            .sink { [weak self] mastodonAuthentication in
                guard let self = self else { return }
                let mastodonUser = mastodonAuthentication?.user
                let username = mastodonUser?.username ?? " "

                self.composeTootAttribute.avatarURL.value = mastodonUser?.avatarImageURL()
                self.composeTootAttribute.displayName.value = {
                    guard let displayName = mastodonUser?.displayName, !displayName.isEmpty else {
                        return username
                    }
                    return displayName
                }()
                self.composeTootAttribute.username.value = username
            }
            .store(in: &disposeBag)
        
        composeTootAttribute.composeContent
            .receive(on: DispatchQueue.main)
            .map { content in
                let content = content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return !content.isEmpty
            }
            .assign(to: \.value, on: isComposeTootBarButtonItemEnabled)
            .store(in: &disposeBag)
        
        composeTootAttribute.composeContent
            .receive(on: DispatchQueue.main)
            .map { content in
                let content = content ?? ""
                return content.isEmpty
            }
            .assign(to: \.value, on: shouldDismiss)
            .store(in: &disposeBag)
    }
    
}
