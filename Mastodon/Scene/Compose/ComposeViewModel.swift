//
//  ComposeViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK

final class ComposeViewModel {
    
    static let composeContentLimit: Int = 500
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let composeKind: ComposeStatusSection.ComposeKind
    let composeStatusAttribute = ComposeStatusItem.ComposeStatusAttribute()
    let isPollComposing = CurrentValueSubject<Bool, Never>(false)
    let isCustomEmojiComposing = CurrentValueSubject<Bool, Never>(false)
    let isContentWarningComposing = CurrentValueSubject<Bool, Never>(false)
    let selectedStatusVisibility = CurrentValueSubject<ComposeToolbarView.VisibilitySelectionType, Never>(.public)
    let activeAuthentication: CurrentValueSubject<MastodonAuthentication?, Never>
    let activeAuthenticationBox: CurrentValueSubject<AuthenticationService.MastodonAuthenticationBox?, Never>
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem>!
    var customEmojiPickerDiffableDataSource: UICollectionViewDiffableDataSource<CustomEmojiPickerSection, CustomEmojiPickerItem>!
    private(set) lazy var publishStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            PublishState.Initial(viewModel: self),
            PublishState.Publishing(viewModel: self),
            PublishState.Fail(viewModel: self),
            PublishState.Discard(viewModel: self),
            PublishState.Finish(viewModel: self),
        ])
        stateMachine.enter(PublishState.Initial.self)
        return stateMachine
    }()
    private(set) lazy var publishStateMachinePublisher = CurrentValueSubject<PublishState?, Never>(nil)
    private(set) var publishDate = Date()   // update it when enter Publishing state

    // UI & UX
    let title: CurrentValueSubject<String, Never>
    let shouldDismiss = CurrentValueSubject<Bool, Never>(true)
    let isPublishBarButtonItemEnabled = CurrentValueSubject<Bool, Never>(false)
    let isMediaToolbarButtonEnabled = CurrentValueSubject<Bool, Never>(true)
    let isPollToolbarButtonEnabled = CurrentValueSubject<Bool, Never>(true)
    let characterCount = CurrentValueSubject<Int, Never>(0)
    
    // custom emojis
    var customEmojiViewModelSubscription: AnyCancellable?
    let customEmojiViewModel = CurrentValueSubject<EmojiService.CustomEmojiViewModel?, Never>(nil)
    let customEmojiPickerInputViewModel = CustomEmojiPickerInputViewModel()
    let isLoadingCustomEmoji = CurrentValueSubject<Bool, Never>(false)
    
    // attachment
    let attachmentServices = CurrentValueSubject<[MastodonAttachmentService], Never>([])
    
    // polls
    let pollOptionAttributes = CurrentValueSubject<[ComposeStatusItem.ComposePollOptionAttribute], Never>([])
    let pollExpiresOptionAttribute = ComposeStatusItem.ComposePollExpiresOptionAttribute()
    
    init(
        context: AppContext,
        composeKind: ComposeStatusSection.ComposeKind,
        initialComposeContent: String? = nil
    ) {
        self.context = context
        self.composeKind = composeKind
        switch composeKind {
        case .post, .mention:       self.title = CurrentValueSubject(L10n.Scene.Compose.Title.newPost)
        case .reply:                self.title = CurrentValueSubject(L10n.Scene.Compose.Title.newReply)
        }
        self.activeAuthentication = CurrentValueSubject(context.authenticationService.activeMastodonAuthentication.value)
        self.activeAuthenticationBox = CurrentValueSubject(context.authenticationService.activeMastodonAuthenticationBox.value)
        // end init
        
        if case let .mention(mastodonUserObjectID) = composeKind {
            context.managedObjectContext.performAndWait {
                let mastodonUser = context.managedObjectContext.object(with: mastodonUserObjectID) as! MastodonUser
                let initialComposeContent = "@" + mastodonUser.acct + " "
                self.composeStatusAttribute.composeContent.value = initialComposeContent
            }
        }
        
        isCustomEmojiComposing
            .assign(to: \.value, on: customEmojiPickerInputViewModel.isCustomEmojiComposing)
            .store(in: &disposeBag)
        
        isContentWarningComposing
            .assign(to: \.value, on: composeStatusAttribute.isContentWarningComposing)
            .store(in: &disposeBag)
        
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
        
        // bind character count
        Publishers.CombineLatest3(
            composeStatusAttribute.composeContent.eraseToAnyPublisher(),
            composeStatusAttribute.isContentWarningComposing.eraseToAnyPublisher(),
            composeStatusAttribute.contentWarningContent.eraseToAnyPublisher()
        )
        .map { composeContent, isContentWarningComposing, contentWarningContent -> Int in
            let composeContent = composeContent ?? ""
            var count = composeContent.count
            if isContentWarningComposing {
                count += contentWarningContent.count
            }
            return count
        }
        .assign(to: \.value, on: characterCount)
        .store(in: &disposeBag)
        // bind compose bar button item UI state
        let isComposeContentEmpty = composeStatusAttribute.composeContent
            .map { ($0 ?? "").isEmpty }
        let isComposeContentValid = composeStatusAttribute.composeContent
            .map { composeContent -> Bool in
                let composeContent = composeContent ?? ""
                return composeContent.count <= ComposeViewModel.composeContentLimit
            }
        let isMediaEmpty = attachmentServices
            .map { $0.isEmpty }
        let isMediaUploadAllSuccess = attachmentServices
            .map { services in
                services.allSatisfy { $0.uploadStateMachineSubject.value is MastodonAttachmentService.UploadState.Finish }
            }
        let isPollAttributeAllValid = pollOptionAttributes
            .map { pollAttributes in
                pollAttributes.allSatisfy { attribute -> Bool in
                    !attribute.option.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            }
        
        let isPublishBarButtonItemEnabledPrecondition1 = Publishers.CombineLatest4(
            isComposeContentEmpty.eraseToAnyPublisher(),
            isComposeContentValid.eraseToAnyPublisher(),
            isMediaEmpty.eraseToAnyPublisher(),
            isMediaUploadAllSuccess.eraseToAnyPublisher()
        )
        .map { isComposeContentEmpty, isComposeContentValid, isMediaEmpty, isMediaUploadAllSuccess -> Bool in
            if isMediaEmpty {
                return isComposeContentValid && !isComposeContentEmpty
            } else {
                return isComposeContentValid && isMediaUploadAllSuccess
            }
        }
        .eraseToAnyPublisher()

        let isPublishBarButtonItemEnabledPrecondition2 = Publishers.CombineLatest4(
            isComposeContentEmpty.eraseToAnyPublisher(),
            isComposeContentValid.eraseToAnyPublisher(),
            isPollComposing.eraseToAnyPublisher(),
            isPollAttributeAllValid.eraseToAnyPublisher()
        )
        .map { isComposeContentEmpty, isComposeContentValid, isPollComposing, isPollAttributeAllValid -> Bool in
            if isPollComposing {
                return isComposeContentValid && !isComposeContentEmpty && isPollAttributeAllValid
            } else {
                return isComposeContentValid && !isComposeContentEmpty
            }
        }
        .eraseToAnyPublisher()
        
        Publishers.CombineLatest(
            isPublishBarButtonItemEnabledPrecondition1,
            isPublishBarButtonItemEnabledPrecondition2
        )
        .map { $0 && $1 }
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
        Publishers.CombineLatest3(
            attachmentServices.eraseToAnyPublisher(),
            isPollComposing.eraseToAnyPublisher(),
            pollOptionAttributes.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] attachmentServices, isPollComposing, pollAttributes in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }
            var snapshot = diffableDataSource.snapshot()
            
            snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .attachment))
            var attachmentItems: [ComposeStatusItem] = []
            for attachmentService in attachmentServices {
                let item = ComposeStatusItem.attachment(attachmentService: attachmentService)
                attachmentItems.append(item)
            }
            snapshot.appendItems(attachmentItems, toSection: .attachment)
            
            snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .poll))
            if isPollComposing {
                var pollItems: [ComposeStatusItem] = []
                for pollAttribute in pollAttributes {
                    let item = ComposeStatusItem.pollOption(attribute: pollAttribute)
                    pollItems.append(item)
                }
                snapshot.appendItems(pollItems, toSection: .poll)
                if pollAttributes.count < 4 {
                    snapshot.appendItems([ComposeStatusItem.pollOptionAppendEntry], toSection: .poll)
                }
                snapshot.appendItems([ComposeStatusItem.pollExpiresOption(attribute: self.pollExpiresOptionAttribute)], toSection: .poll)
            }
            
            diffableDataSource.apply(snapshot)
            
            // drive service upload state
            // make image upload in the queue
            for attachmentService in attachmentServices {
                // skip when prefix N task when task finish OR fail OR uploading
                guard let currentState = attachmentService.uploadStateMachine.currentState else { break }
                if currentState is MastodonAttachmentService.UploadState.Fail {
                    continue
                }
                if currentState is MastodonAttachmentService.UploadState.Finish {
                    continue
                }
                if currentState is MastodonAttachmentService.UploadState.Uploading {
                    break
                }
                // trigger uploading one by one
                if currentState is MastodonAttachmentService.UploadState.Initial {
                    attachmentService.uploadStateMachine.enter(MastodonAttachmentService.UploadState.Uploading.self)
                    break
                }
            }
        }
        .store(in: &disposeBag)
        
        // bind delegate
        attachmentServices
            .sink { [weak self] attachmentServices in
                guard let self = self else { return }
                attachmentServices.forEach { $0.delegate = self }
            }
            .store(in: &disposeBag)
        
        pollOptionAttributes
            .sink { [weak self] pollAttributes in
                guard let self = self else { return }
                pollAttributes.forEach { $0.delegate = self }
            }
            .store(in: &disposeBag)
        
        // bind compose toolbar UI state
        Publishers.CombineLatest(
            isPollComposing.eraseToAnyPublisher(),
            attachmentServices.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] isPollComposing, attachmentServices in
            guard let self = self else { return }
            let shouldMediaDisable = isPollComposing || attachmentServices.count >= 4
            let shouldPollDisable = attachmentServices.count > 0
            
            self.isMediaToolbarButtonEnabled.value = !shouldMediaDisable
            self.isPollToolbarButtonEnabled.value = !shouldPollDisable
        })
        .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ComposeViewModel {
    func createNewPollOptionIfPossible() {
        guard pollOptionAttributes.value.count < 4 else { return }
        
        let attribute = ComposeStatusItem.ComposePollOptionAttribute()
        pollOptionAttributes.value = pollOptionAttributes.value + [attribute]
    }
    
    func updatePublishDate() {
        publishDate = Date()
    }
}

// MARK: - MastodonAttachmentServiceDelegate
extension ComposeViewModel: MastodonAttachmentServiceDelegate {
    func mastodonAttachmentService(_ service: MastodonAttachmentService, uploadStateDidChange state: MastodonAttachmentService.UploadState?) {
        // trigger new output event
        attachmentServices.value = attachmentServices.value
    }
}

// MARK: - ComposePollAttributeDelegate
extension ComposeViewModel: ComposePollAttributeDelegate {
    func composePollAttribute(_ attribute: ComposeStatusItem.ComposePollOptionAttribute, pollOptionDidChange: String?) {
        // trigger update
        // pollOptionAttributes.value = pollOptionAttributes.value
    }
}
