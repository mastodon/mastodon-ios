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

public final class ComposeContentViewModel: NSObject, ObservableObject {
    
    let logger = Logger(subsystem: "ComposeContentViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // tableViewCell
    let composeReplyToTableViewCell = ComposeReplyToTableViewCell()
    let composeContentTableViewCell = ComposeContentTableViewCell()
    
    // input
    let context: AppContext
    let kind: Kind
    
    @Published var viewLayoutFrame = ViewLayoutFrame()
    
    // author (me)
    @Published var authContext: AuthContext
    
    // auto-complete info
    @Published var autoCompleteRetryLayoutTimes = 0
    @Published var autoCompleteInfo: AutoCompleteInfo? = nil
    
    // output
    
    // limit
    @Published public var maxTextInputLimit = 500
    
    // content
    public weak var contentMetaText: MetaText? {
        didSet {
//            guard let textView = contentMetaText?.textView else { return }
//            customEmojiPickerInputViewModel.configure(textInput: textView)
        }
    }
    @Published public var initialContent = ""
    @Published public var content = ""
    @Published public var contentWeightedLength = 0
    @Published public var isContentEmpty = true
    @Published public var isContentValid = true
    @Published public var isContentEditing = false
    
    // content warning
    weak var contentWarningMetaText: MetaText? {
        didSet {
            //guard let textView = contentWarningMetaText?.textView else { return }
            //customEmojiPickerInputViewModel.configure(textInput: textView)
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
    // @Published public internal(set) var isMediaValid = true
    
    // poll
    @Published var isPollActive = false
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
    
    // visibility
    @Published var visibility: Mastodon.Entity.Status.Visibility
    
    // UI & UX
    @Published var replyToCellFrame: CGRect = .zero
    @Published var contentCellFrame: CGRect = .zero
    @Published var contentTextViewFrame: CGRect = .zero
    @Published var scrollViewState: ScrollViewState = .fold

    public init(
        context: AppContext,
        authContext: AuthContext,
        kind: Kind
    ) {
        self.context = context
        self.authContext = authContext
        self.kind = kind
        self.visibility = {
            // default private when user locked
            var visibility: Mastodon.Entity.Status.Visibility = {
                guard let author = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: context.managedObjectContext)?.user else {
                    return .public
                }
                return author.locked ? .private : .public
            }()
            // set visibility for reply post
            switch kind {
            case .reply(let record):
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
            default:
                break
            }
            return visibility
        }()
        super.init()
        // end init
        
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
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ComposeContentViewModel {
    public enum Kind {
        case post
        case hashtag(hashtag: String)
        case mention(user: ManagedObjectRecord<MastodonUser>)
        case reply(status: ManagedObjectRecord<Status>)
    }
    
    public enum ScrollViewState {
        case fold       // snap to input
        case expand     // snap to reply
    }
}

extension ComposeContentViewModel {
    struct AutoCompleteInfo {
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
                return "The post poll is invalid"  // TODO: i18n
            }
        }
        
        public var failureReason: String? {
            switch self {
            case .pollHasEmptyOption:
                return "The poll has empty option"   // TODO: i18n
            }
        }
    }
    
    public func statusPublisher() throws -> StatusPublisher {
        let authContext = self.authContext
        
        // author
        let managedObjectContext = self.context.managedObjectContext
        var _author: ManagedObjectRecord<MastodonUser>?
        managedObjectContext.performAndWait {
            _author = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: managedObjectContext)?.user.asRecrod
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
                switch self.kind {
                case .reply(let status):    return status
                default:                    return nil
                }
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
