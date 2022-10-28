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
import MastodonCore
import Meta
import MastodonMeta
import MetaTextKit

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
    @Published var authContext: AuthContext
    
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
    @Published public var maxPollOptionLimit = 4
    
    // emoji
    @Published var isEmojiActive = false
    
    // UI & UX
    @Published var replyToCellFrame: CGRect = .zero
    @Published var contentCellFrame: CGRect = .zero
    @Published var scrollViewState: ScrollViewState = .fold


    public init(
        context: AppContext,
        authContext: AuthContext,
        kind: Kind
    ) {
        self.context = context
        self.authContext = authContext
        self.kind = kind
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
    func createNewPollOptionIfCould() {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard pollOptions.count < maxPollOptionLimit else { return }
        let option = PollComposeItem.Option()
        option.shouldBecomeFirstResponder = true
        pollOptions.append(option)
    }
}

// MARK: - UITextViewDelegate
extension ComposeContentViewModel: UITextViewDelegate {
    public func textViewDidBeginEditing(_ textView: UITextView) {
        switch textView {
        case contentMetaText?.textView:
            isContentEditing = true
        case contentWarningMetaText?.textView:
            isContentWarningEditing = true
        default:
            break
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        switch textView {
        case contentMetaText?.textView:
            isContentEditing = false
        case contentWarningMetaText?.textView:
            isContentWarningEditing = false
        default:
            break
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        switch textView {
        case contentMetaText?.textView:
            return true
        case contentWarningMetaText?.textView:
            let isReturn = text == "\n"
            if isReturn {
                setContentTextViewFirstResponderIfNeeds()
            }
            return !isReturn
        default:
            assertionFailure()
            return true
        }
    }
    
    func insertContentText(text: String) {
        guard let contentMetaText = self.contentMetaText else { return }
        // FIXME: smart prefix and suffix
        let string = contentMetaText.textStorage.string
        let isEmpty = string.isEmpty
        let hasPrefix = string.hasPrefix(" ")
        if hasPrefix || isEmpty {
            contentMetaText.textView.insertText(text)
        } else {
            contentMetaText.textView.insertText(" " + text)
        }
    }
    
    func setContentTextViewFirstResponderIfNeeds() {
        guard let contentMetaText = self.contentMetaText else { return }
        guard !contentMetaText.textView.isFirstResponder else { return }
        contentMetaText.textView.becomeFirstResponder()
    }
    
    func setContentWarningTextViewFirstResponderIfNeeds() {
        guard let contentWarningMetaText = self.contentWarningMetaText else { return }
        guard !contentWarningMetaText.textView.isFirstResponder else { return }
        contentWarningMetaText.textView.becomeFirstResponder()
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
