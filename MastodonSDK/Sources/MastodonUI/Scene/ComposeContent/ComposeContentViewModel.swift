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
import MastodonCommon
import MastodonCore
import MastodonSDK
import MastodonLocalization
import CoreData
import UniformTypeIdentifiers

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
    var draft: Draft?
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
    @Published public var pollExpireConfigurationOption: Draft.Poll.Expiration = .oneDay
    @Published public var pollMultipleConfigurationOption: PollComposeItem.MultipleConfiguration.Option = false

    @Published public var maxPollOptionLimit = 4
    
    // emoji
    @Published var isEmojiActive = false
    let customEmojiViewModel: EmojiService.CustomEmojiViewModel?
    let customEmojiPickerInputViewModel = CustomEmojiPickerInputViewModel()
    @Published var isLoadingCustomEmoji = false
    
    // visibility
    @Published public var visibility: MastodonVisibility
    
    // language
    @Published public var language: String
    @Published public private(set) var recentLanguages: [String]

    // UI & UX
    @Published var replyToCellFrame: CGRect = .zero
    @Published var contentCellFrame: CGRect = .zero
    @Published var contentTextViewFrame: CGRect = .zero
    @Published var scrollViewState: ScrollViewState = .fold
    
    @Published var characterCount: Int = 0
    
    @Published public private(set) var isPublishBarButtonItemEnabled = true
    @Published var isAttachmentButtonEnabled = false
    @Published var isPollButtonEnabled = false
    
    public var shouldDismiss: Bool {
        let contentDirty = !content.isEmpty && content.trimmingCharacters(in: .whitespacesAndNewlines) != initialContent
        let attachmentDirty = !attachmentViewModels.isEmpty || isPollActive
        let dirty = contentDirty || !contentWarning.isEmpty || attachmentDirty
        return !dirty
    }
    
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
        self.draft = nil
        self.visibility = {
            // default private when user locked
            var visibility: MastodonVisibility = {
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
        
        let recentLanguages = context.settingService.currentSetting.value?.recentLanguages ?? []
        self.recentLanguages = recentLanguages
        self.language = recentLanguages.first ?? Locale.current.languageCode ?? "en"
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

        _init()
    }
    
    public init(
        context: AppContext,
        authContext: AuthContext,
        draft: Draft
    ) {
        self.context = context
        self.authContext = authContext
        self.destination = draft.replyTo.map { .reply(parent: $0.asRecord) } ?? .topLevel
        self.draft = draft
        self.customEmojiViewModel = context.emojiService.dequeueCustomEmojiViewModel(
            for: authContext.mastodonAuthenticationBox.domain
        )
        self.visibility = draft.visibility
        self.language = draft.language
        let recentLanguages = context.settingService.currentSetting.value?.recentLanguages ?? []
        self.recentLanguages = recentLanguages
        super.init()
        _init()
        
        self.content = draft.content
        if let contentWarning = draft.contentWarning {
            self.contentWarning = contentWarning
            self.isContentWarningActive = true
        }
        self.attachmentViewModels = draft.attachments.map { attachment in
            let input: AttachmentViewModel.Input
            switch attachment.status {
            case nil: input = .url(attachment.fileURL)
            case .compressed: input = .draft(attachment.fileURL, remoteID: nil)
            case .uploaded(let remoteID): input = .draft(attachment.fileURL, remoteID: remoteID)
            }
            return AttachmentViewModel(
                api: context.apiService,
                authContext: authContext,
                input: input,
                sizeLimit: sizeLimit,
                delegate: self
            )
        }
    }

    private func _init() {
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

        // languages
        context.settingService.currentSetting
            .flatMap { settings in
                if let settings {
                    return settings.publisher(for: \.recentLanguages, options: .initial).eraseToAnyPublisher()
                } else if let code = Locale.current.languageCode {
                    return Just([code]).eraseToAnyPublisher()
                }
                return Just([]).eraseToAnyPublisher()
            }
            .assign(to: &$recentLanguages)
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
    public func saveToDraft(in context: NSManagedObjectContext) async throws {
        var attachments: [Draft.Attachment] = []
        let attachmentsFolder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("draft-attachments", isDirectory: true)
        try FileManager.default.createDirectory(at: attachmentsFolder, withIntermediateDirectories: true)

        for attachment in self.attachmentViewModels {
            let fileURL: URL
            var output = attachment.output
            if output == nil, let compressTask = attachment.compressTask {
                (output, _) = try await compressTask.value
            }
            switch output {
            case nil:
                if attachment.error == nil {
                    assertionFailure("Should be impossible!")
                }
                // remove the attachment from the list. No other choice unfortunately
                continue
            case .image(let data, let kind):
                fileURL = attachmentsFolder.appendingPathComponent(attachment.id.uuidString, conformingTo: kind.type)
                try data.write(to: fileURL)
            case .video(let url, let mimeType):
                fileURL = attachmentsFolder.appendingPathComponent(attachment.id.uuidString, conformingTo: UTType(mimeType: mimeType) ?? .mpeg4Movie)
                // keep a copy until we’re done with it instead of allowing the system to clean up
                try FileManager.default.copyItem(at: url, to: fileURL)
            }
            switch attachment.uploadState {
            case .none, .compressing:
                attachments.append(.init(fileURL: fileURL, status: nil))
            case .ready, .fail, .uploading:
                attachments.append(.init(fileURL: fileURL, status: .compressed))
            case .finish:
                // if in the .finish state, `uploadResult` must be set
                attachments.append(.init(fileURL: fileURL, status: .uploaded(remoteID: attachment.uploadResult!.id)))
            }
        }
        let property = Draft.Property(
            content: content,
            contentWarning: isContentWarningActive ? contentWarning : nil,
            language: language,
            visibility: visibility,
            attachments: attachments,
            poll: isPollActive ? Draft.Poll(
                items: pollOptions.map(\.text),
                expiration: pollExpireConfigurationOption,
                multiple: pollMultipleConfigurationOption
            ) : nil
        )
        let oldAttachments = draft?.attachments ?? []
        try await context.performChanges { [self] in
            let relationship: Draft.Relationship = {
                let replyTo: Status?
                if case .reply(let parent) = destination {
                    replyTo = parent.object(in: context)
                } else {
                    replyTo = nil
                }
                let authentication = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: context)!
                return .init(author: authentication.user, replyTo: replyTo)
            }()
            if let draft = self.draft {
                draft.configure(property: property)
                draft.configure(relationship: relationship)
            } else {
                self.draft = Draft.insert(into: context, property: property, relationship: relationship)
            }
        }
        for attachment in oldAttachments {
            attachment.prepareForDeletion()
        }
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
        
        Task {
            try await self.saveToDraft(in: self.context.managedObjectContext)
        }
        
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
        
        // save language to recent languages
        if let settings = context.settingService.currentSetting.value {
            Task.detached(priority: .background) { [language] in
                try await settings.managedObjectContext?.performChanges {
                    settings.recentLanguages = [language] + settings.recentLanguages.filter { $0 != language }
                }
            }
        }
        
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
            visibility: visibility,
            language: language,
            cleanup: self.discardDraft
        )
    }   // end func publisher()
    
    public func discardDraft() {
        if let draft {
            let managedObjectContext = context.managedObjectContext
            Task {
                try? await managedObjectContext.perform {
                    managedObjectContext.delete(draft)
                }
            }
            self.draft = nil
        }
    }
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
