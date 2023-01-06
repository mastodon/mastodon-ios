//
//  ComposeContentViewModel.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import Meta
import MetaTextKit
import MastodonMeta
import MastodonCore
import MastodonSDK
import MastodonLocalization

public protocol ComposeContentViewModelDelegate: AnyObject {
    func composeContentViewModel(_ viewModel: ComposeContentViewModel, handleAutoComplete info: ComposeContentViewModel.AutoCompleteInfo) -> Bool
}

public final class ComposeContentViewModel: NSObject, ObservableObject {
    
    let logger = Logger(subsystem: "ComposeContentViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // tableViewCell
    let composeReplyToTableViewCell = ComposeReplyToTableViewCell()
    let composeContentTableViewCell = ComposeContentTableViewCell()
    
    // input
    let context: AppContext
    let destination: Destination
    weak var delegate: ComposeContentViewModelDelegate?
    
    @Published var viewLayoutFrame = ViewLayoutFrame()
    
    // author (me)
    @Published var authContext: AuthContext
    
    // auto-complete info
    @Published var autoCompleteRetryLayoutTimes = 0
    @Published var autoCompleteInfo: AutoCompleteInfo? = nil
    
    // emoji
    var customEmojiPickerDiffableDataSource: UICollectionViewDiffableDataSource<CustomEmojiPickerSection, CustomEmojiPickerItem>?
    
    // output
    
    // limit
    @Published public var maxTextInputLimit = 500
    
    // content
    public weak var contentMetaText: MetaText? {
        didSet {
            guard let textView = contentMetaText?.textView else { return }
            customEmojiPickerInputViewModel.configure(textInput: textView)
        }
    }
    // allow dismissing the compose view without confirmation if content == intialContent
    @Published public var initialContent = ""
    @Published public var content = ""
    @Published public var contentWeightedLength = 0
    @Published public var isContentEmpty = true
    @Published public var isContentValid = true
    @Published public var isContentEditing = false
    
    // content warning
    weak var contentWarningMetaText: MetaText? {
        didSet {
            guard let textView = contentWarningMetaText?.textView else { return }
            customEmojiPickerInputViewModel.configure(textInput: textView)
        }
    }
    @Published public var isContentWarningActive = false
    @Published public var contentWarning = ""
    @Published public var contentWarningWeightedLength = 0  // set 0 when not composing
    @Published public var isContentWarningEditing = false

    // author
    @Published var avatarURL: URL?
    @Published var name: MetaContent = PlaintextMetaContent(string: "")
    @Published var username: String = ""
    
    // attachment
    @Published public var attachmentViewModels: [AttachmentViewModel] = []
    @Published public var maxMediaAttachmentLimit = 4
    @Published public internal(set) var maxImageMediaSizeLimitInByte = 10 * 1024 * 1024     // 10 MiB
    
    // poll
    @Published public var isPollActive = false
    @Published public var pollOptions: [PollComposeItem.Option] = {
        // initial with 2 options
        var options: [PollComposeItem.Option] = []
        options.append(PollComposeItem.Option())
        options.append(PollComposeItem.Option())
        return options
    }()
    @Published public var pollExpireConfigurationOption: PollComposeItem.ExpireConfiguration.Option = .oneDay
    @Published public var pollMultipleConfigurationOption: PollComposeItem.MultipleConfiguration.Option = false

    @Published public var maxPollOptionLimit = 4
    
    // emoji
    @Published var isEmojiActive = false
    let customEmojiViewModel: EmojiService.CustomEmojiViewModel?
    let customEmojiPickerInputViewModel = CustomEmojiPickerInputViewModel()
    @Published var isLoadingCustomEmoji = false
    
    // visibility
    @Published public var visibility: Mastodon.Entity.Status.Visibility
    
    // UI & UX
    @Published var replyToCellFrame: CGRect = .zero
    @Published var contentCellFrame: CGRect = .zero
    @Published var contentTextViewFrame: CGRect = .zero
    @Published var scrollViewState: ScrollViewState = .fold
    
    @Published var characterCount: Int = 0
    
    @Published public private(set) var isPublishBarButtonItemEnabled = true
    @Published var isAttachmentButtonEnabled = false
    @Published var isPollButtonEnabled = false
    
    @Published public private(set) var shouldDismiss = true
    
    // size limit
    public var sizeLimit: AttachmentViewModel.SizeLimit {
        AttachmentViewModel.SizeLimit(
            image: maxImageMediaSizeLimitInByte,
            video: nil
        )
    }

    public init(
        context: AppContext,
        authContext: AuthContext,
        destination: Destination,
        initialContent: String
    ) {
        self.context = context
        self.authContext = authContext
        self.destination = destination
        self.visibility = {
            // default private when user locked
            var visibility: Mastodon.Entity.Status.Visibility = {
                guard let author = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: context.managedObjectContext)?.user else {
                    return .public
                }
                return author.locked ? .private : .public
            }()
            // set visibility for reply post
            if case .reply(let record) = destination {
                context.managedObjectContext.performAndWait {
                    guard let status = record.object(in: context.managedObjectContext) else {
                        assertionFailure()
                        return
                    }
                    let repliedStatusVisibility = status.visibility
                    switch repliedStatusVisibility {
                    case .public, .unlisted:
                        // keep default
                        break
                    case .private:
                        visibility = .private
                    case .direct:
                        visibility = .direct
                    case ._other:
                        assertionFailure()
                        break
                    }
                }
            }
            return visibility
        }()
        self.customEmojiViewModel = context.emojiService.dequeueCustomEmojiViewModel(
            for: authContext.mastodonAuthenticationBox.domain
        )
        super.init()
        // end init
        
        // setup initial value
        let initialContentWithSpace = initialContent.isEmpty ? "" : initialContent + " "
        switch destination {
        case .reply(let record):
            context.managedObjectContext.performAndWait {
                guard let status = record.object(in: context.managedObjectContext) else {
                    assertionFailure()
                    return
                }
                let author = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: context.managedObjectContext)?.user

                var mentionAccts: [String] = []
                if author?.id != status.author.id {
                    mentionAccts.append("@" + status.author.acct)
                }
                let mentions = status.mentions
                    .filter { author?.id != $0.id }
                for mention in mentions {
                    let acct = "@" + mention.acct
                    guard !mentionAccts.contains(acct) else { continue }
                    mentionAccts.append(acct)
                }
                for acct in mentionAccts {
                    UITextChecker.learnWord(acct)
                }
                if let spoilerText = status.spoilerText, !spoilerText.isEmpty {
                    self.isContentWarningActive = true
                    self.contentWarning = spoilerText
                }

                let initialComposeContent = mentionAccts.joined(separator: " ")
                let preInsertedContent = initialComposeContent.isEmpty ? "" : initialComposeContent + " "
                self.initialContent = preInsertedContent + initialContentWithSpace
                self.content = preInsertedContent + initialContentWithSpace
            }
        case .topLevel:
            self.initialContent = initialContentWithSpace
            self.content = initialContentWithSpace
        }

        // set limit
        let _configuration: Mastodon.Entity.Instance.Configuration? = {
            var configuration: Mastodon.Entity.Instance.Configuration? = nil
            context.managedObjectContext.performAndWait {
                guard let authentication = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: context.managedObjectContext)
                else { return }
                configuration = authentication.instance?.configuration
            }
            return configuration
        }()
        if let configuration = _configuration {
            // set character limit
            if let maxCharacters = configuration.statuses?.maxCharacters {
                maxTextInputLimit = maxCharacters
            }
            // set media limit
            if let maxMediaAttachments = configuration.statuses?.maxMediaAttachments {
                maxMediaAttachmentLimit = maxMediaAttachments
            }
            // set poll option limit
            if let maxOptions = configuration.polls?.maxOptions {
                maxPollOptionLimit = maxOptions
            }
            // set photo attachment limit
            if let imageSizeLimit = configuration.mediaAttachments?.imageSizeLimit {
                maxImageMediaSizeLimitInByte = imageSizeLimit
            }
            // TODO: more limit
        }
        
        bind()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ComposeContentViewModel {
    private func bind() {
        // bind author
        $authContext
            .sink { [weak self] authContext in
                guard let self = self else { return }
                guard let user = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: self.context.managedObjectContext)?.user else { return }
                self.avatarURL = user.avatarImageURL()
                self.name = user.nameMetaContent ?? PlaintextMetaContent(string: user.displayNameWithFallback)
                self.username = user.acctWithDomain
            }
            .store(in: &disposeBag)
        
        // bind text
        $content
            .map { $0.count }
            .assign(to: &$contentWeightedLength)
        
        Publishers.CombineLatest(
            $contentWarning,
            $isContentWarningActive
        )
        .map { $1 ? $0.count : 0 }
        .assign(to: &$contentWarningWeightedLength)
        
        Publishers.CombineLatest3(
            $contentWeightedLength,
            $contentWarningWeightedLength,
            $maxTextInputLimit
        )
        .map { $0 + $1 <= $2 }
        .assign(to: &$isContentValid)
        
        // bind attachment
        $attachmentViewModels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    try await self.uploadMediaInQueue()
                }
            }
            .store(in: &disposeBag)
        
        // bind emoji inputView
        $isEmojiActive.assign(to: &customEmojiPickerInputViewModel.$isCustomEmojiComposing)
        
        // bind toolbar
        Publishers.CombineLatest3(
            $isPollActive,
            $attachmentViewModels,
            $maxMediaAttachmentLimit
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isPollActive, attachmentViewModels, maxMediaAttachmentLimit in
            guard let self = self else { return }
            let shouldMediaDisable = isPollActive || attachmentViewModels.count >= maxMediaAttachmentLimit
            let shouldPollDisable = attachmentViewModels.count > 0
            
            self.isAttachmentButtonEnabled = !shouldMediaDisable
            self.isPollButtonEnabled = !shouldPollDisable
        }
        .store(in: &disposeBag)
        
        // bind status content character count
        Publishers.CombineLatest3(
            $contentWeightedLength,
            $contentWarningWeightedLength,
            $isContentWarningActive
        )
        .map { contentWeightedLength, contentWarningWeightedLength, isContentWarningActive -> Int in
            var count = contentWeightedLength
            if isContentWarningActive {
                count += contentWarningWeightedLength
            }
            return count
        }
        .assign(to: &$characterCount)
        
        // bind compose bar button item UI state
        let isComposeContentEmpty = $content
            .map { $0.isEmpty }
        let isComposeContentValid = Publishers.CombineLatest(
            $characterCount,
            $maxTextInputLimit
        )
        .map { characterCount, maxTextInputLimit in
            characterCount <= maxTextInputLimit
        }

        let isMediaEmpty = $attachmentViewModels
            .map { $0.isEmpty }
        let isMediaUploadAllSuccess = $attachmentViewModels
            .map { attachmentViewModels in
                return Publishers.MergeMany(attachmentViewModels.map { $0.$uploadState })
                    .delay(for: 0.3, scheduler: DispatchQueue.main)     // convert to outputs with delay. Due to @Published emit before changes
                    .map { _ in attachmentViewModels.map { $0.uploadState } }
            }
            .switchToLatest()
            .map { outputs in
                guard outputs.allSatisfy({ $0 == .finish }) else { return false }
                return true
            }
            .prepend(true)
        
        let isPollOptionsAllValid = $pollOptions
            .map { options in
                return Publishers.MergeMany(options.map { $0.$text })
                    .delay(for: 0.3, scheduler: DispatchQueue.main)     // convert to outputs with delay. Due to @Published emit before changes
                    .map { _ in options.map { $0.text } }
            }
            .switchToLatest()
            .map { outputs in
                return outputs.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }
            .prepend(true)
        
        let isPublishBarButtonItemEnabledPrecondition1 = Publishers.CombineLatest4(
            isComposeContentEmpty,
            isComposeContentValid,
            isMediaEmpty,
            isMediaUploadAllSuccess
        )
        .map { isComposeContentEmpty, isComposeContentValid, isMediaEmpty, isMediaUploadAllSuccess -> Bool in
            if isMediaEmpty {
                return isComposeContentValid && !isComposeContentEmpty
            } else {
                return isComposeContentValid && isMediaUploadAllSuccess
            }
        }
        .eraseToAnyPublisher()

        let isPublishBarButtonItemEnabledPrecondition2 = Publishers.CombineLatest(
            $isPollActive,
            isPollOptionsAllValid
        )
        .map { isPollActive, isPollOptionsAllValid -> Bool in
            if isPollActive {
                return isPollOptionsAllValid
            } else {
                return true
            }
        }
        .eraseToAnyPublisher()

        Publishers.CombineLatest(
            isPublishBarButtonItemEnabledPrecondition1,
            isPublishBarButtonItemEnabledPrecondition2
        )
        .map { $0 && $1 }
        .assign(to: &$isPublishBarButtonItemEnabled)
        
        // bind modal dismiss state
        $content
            .receive(on: DispatchQueue.main)
            .map { content in
                if content.isEmpty {
                    return true
                }
                // if the trimmed content equal to initial content
                return content.trimmingCharacters(in: .whitespacesAndNewlines) == self.initialContent
            }
            .assign(to: &$shouldDismiss)
    }
}

extension ComposeContentViewModel {
    public enum Destination {
        case topLevel
        case reply(parent: ManagedObjectRecord<Status>)
    }
    
    public enum ScrollViewState {
        case fold       // snap to input
        case expand     // snap to reply
    }
}

extension ComposeContentViewModel {
    public struct AutoCompleteInfo {
        // model
        let inputText: Substring
        // range
        let symbolRange: Range<String.Index>
        let symbolString: Substring
        let toCursorRange: Range<String.Index>
        let toCursorString: Substring
        let toHighlightEndRange: Range<String.Index>
        let toHighlightEndString: Substring
        // geometry
        var textBoundingRect: CGRect = .zero
        var symbolBoundingRect: CGRect = .zero
    }
}

extension ComposeContentViewModel {
    func createNewPollOptionIfCould() {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard pollOptions.count < maxPollOptionLimit else { return }
        let option = PollComposeItem.Option()
        option.shouldBecomeFirstResponder = true
        pollOptions.append(option)
    }
}

extension ComposeContentViewModel {
    public enum ComposeError: LocalizedError {
        case pollHasEmptyOption
        
        public var errorDescription: String? {
            switch self {
            case .pollHasEmptyOption:
                return L10n.Scene.Compose.Poll.thePollIsInvalid
            }
        }
        
        public var failureReason: String? {
            switch self {
            case .pollHasEmptyOption:
                return L10n.Scene.Compose.Poll.thePollHasEmptyOption
            }
        }
    }
    
    public func statusPublisher() throws -> StatusPublisher {
        let authContext = self.authContext
        
        // author
        let managedObjectContext = self.context.managedObjectContext
        var _author: ManagedObjectRecord<MastodonUser>?
        managedObjectContext.performAndWait {
            _author = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: managedObjectContext)?.user.asRecord
        }
        guard let author = _author else {
            throw AppError.badAuthentication
        }
        
        // poll
        _ = try {
            guard isPollActive else { return }
            let isAllNonEmpty = pollOptions
                .map { $0.text }
                .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            guard isAllNonEmpty else {
                throw ComposeError.pollHasEmptyOption
            }
        }()
        
        return MastodonStatusPublisher(
            author: author,
            replyTo: {
                if case .reply(let status) = destination {
                    return status
                }
                return nil
            }(),
            isContentWarningComposing: isContentWarningActive,
            contentWarning: contentWarning,
            content: content,
            isMediaSensitive: isContentWarningActive,
            attachmentViewModels: attachmentViewModels,
            isPollComposing: isPollActive,
            pollOptions: pollOptions,
            pollExpireConfigurationOption: pollExpireConfigurationOption,
            pollMultipleConfigurationOption: pollMultipleConfigurationOption,
            visibility: visibility
        )
    }   // end func publisher()
}

extension ComposeContentViewModel {
    
    public enum AttachmentPrecondition: Error, LocalizedError {
        case videoAttachWithPhoto
        case moreThanOneVideo

        public var errorDescription: String? {
            return L10n.Common.Alerts.PublishPostFailure.title
        }

        public var failureReason: String? {
            switch self {
            case .videoAttachWithPhoto:
                return L10n.Common.Alerts.PublishPostFailure.AttachmentsMessage.videoAttachWithPhoto
            case .moreThanOneVideo:
                return L10n.Common.Alerts.PublishPostFailure.AttachmentsMessage.moreThanOneVideo
            }
        }
    }

    // check exclusive limit:
    // - up to 1 video
    // - up to N photos
    public func checkAttachmentPrecondition() throws {
        let attachmentViewModels = self.attachmentViewModels
        guard !attachmentViewModels.isEmpty else { return }
        
        var photoAttachmentViewModels: [AttachmentViewModel] = []
        var videoAttachmentViewModels: [AttachmentViewModel] = []
        attachmentViewModels.forEach { attachmentViewModel in
            guard let output = attachmentViewModel.output else {
                assertionFailure()
                return
            }
            switch output {
            case .image:
                photoAttachmentViewModels.append(attachmentViewModel)
            case .video:
                videoAttachmentViewModels.append(attachmentViewModel)
            }
        }

        if !videoAttachmentViewModels.isEmpty {
            guard videoAttachmentViewModels.count == 1 else {
                throw AttachmentPrecondition.moreThanOneVideo
            }
            guard photoAttachmentViewModels.isEmpty else {
                throw AttachmentPrecondition.videoAttachWithPhoto
            }
        }
    }
    
}

// MARK: - DeleteBackwardResponseTextFieldRelayDelegate
extension ComposeContentViewModel: DeleteBackwardResponseTextFieldRelayDelegate {

    func deleteBackwardResponseTextFieldDidReturn(_ textField: DeleteBackwardResponseTextField) {
        let index = textField.tag
        if index + 1 == pollOptions.count {
            createNewPollOptionIfCould()
        } else if index < pollOptions.count {
            pollOptions[index + 1].textField?.becomeFirstResponder()
        }
    }
    
    func deleteBackwardResponseTextField(_ textField: DeleteBackwardResponseTextField, textBeforeDelete: String?) {
        guard (textBeforeDelete ?? "").isEmpty else {
            // do nothing when not empty
            return
        }
        
        let index = textField.tag
        guard index > 0 else {
            // do nothing at first row
            return
        }
        
        func optionBeforeRemoved() -> PollComposeItem.Option? {
            guard index > 0 else { return nil }
            let indexBeforeRemoved = pollOptions.index(before: index)
            let itemBeforeRemoved = pollOptions[indexBeforeRemoved]
            return itemBeforeRemoved
            
        }
        
        func optionAfterRemoved() -> PollComposeItem.Option? {
            guard index < pollOptions.count - 1 else { return nil }
            let indexAfterRemoved = pollOptions.index(after: index)
            let itemAfterRemoved = pollOptions[indexAfterRemoved]
            return itemAfterRemoved
        }
        
        // move first responder
        let _option = optionBeforeRemoved() ?? optionAfterRemoved()
        _option?.textField?.becomeFirstResponder()
        
        guard pollOptions.count > 2 else {
            // remove item when more then 2 options
            return
        }
        pollOptions.remove(at: index)
    }
    
}

// MARK: - AttachmentViewModelDelegate
extension ComposeContentViewModel: AttachmentViewModelDelegate {
    
    public func attachmentViewModel(
        _ viewModel: AttachmentViewModel,
        uploadStateValueDidChange state: AttachmentViewModel.UploadState
    ) {
        Task {
            try await uploadMediaInQueue()
        }
    }
    
    @MainActor
    func uploadMediaInQueue() async throws {
        for (i, attachmentViewModel) in attachmentViewModels.enumerated() {
            switch attachmentViewModel.uploadState {
            case .none:
                return
            case .compressing:
                return
            case .ready:
                let count = self.attachmentViewModels.count
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): upload \(i)/\(count) attachment")
                try await attachmentViewModel.upload()
                return
            case .uploading:
                return
            case .fail:
                return
            case .finish:
                continue
            }
        }
    }
    
    public func attachmentViewModel(
        _ viewModel: AttachmentViewModel,
        actionButtonDidPressed action: AttachmentViewModel.Action
    ) {
        switch action {
        case .retry:
            Task {
                try await viewModel.upload(isRetry: true)                
            }
        case .remove:
            attachmentViewModels.removeAll(where: { $0 === viewModel })
            Task {
                try await uploadMediaInQueue()
            }
        }
    }
}
