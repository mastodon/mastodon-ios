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
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonMeta
import MastodonUI

final class ComposeViewModel: NSObject {
    
    let logger = Logger(subsystem: "ComposeViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()

    let id = UUID()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let kind: ComposeContentViewModel.Kind
    
//    var authenticationBox: MastodonAuthenticationBox {
//        authContext.mastodonAuthenticationBox
//    }
//
//    @Published var isPollComposing = false
//    @Published var isCustomEmojiComposing = false
//    @Published var isContentWarningComposing = false
//
//    @Published var selectedStatusVisibility: ComposeToolbarView.VisibilitySelectionType
//    @Published var repliedToCellFrame: CGRect = .zero
//    @Published var autoCompleteRetryLayoutTimes = 0
//    @Published var autoCompleteInfo: ComposeViewController.AutoCompleteInfo? = nil

//    let traitCollectionDidChangePublisher = CurrentValueSubject<Void, Never>(Void())      // use CurrentValueSubject to make initial event emit
//    var isViewAppeared = false
    
    // output
//    let instanceConfiguration: Mastodon.Entity.Instance.Configuration?
//    var composeContentLimit: Int {
//        guard let maxCharacters = instanceConfiguration?.statuses?.maxCharacters else { return 500 }
//        return max(1, maxCharacters)
//    }
//    var maxMediaAttachments: Int {
//        guard let maxMediaAttachments = instanceConfiguration?.statuses?.maxMediaAttachments else {
//            return 4
//        }
//        // FIXME: update timeline media preview UI
//        return min(4, max(1, maxMediaAttachments))
//        // return max(1, maxMediaAttachments)
//    }
//    var maxPollOptions: Int {
//        guard let maxOptions = instanceConfiguration?.polls?.maxOptions else { return 4 }
//        return max(2, maxOptions)
//    }
//
//    let composeStatusAttribute = ComposeStatusItem.ComposeStatusAttribute()
//    let composeStatusContentTableViewCell = ComposeStatusContentTableViewCell()
//    let composeStatusAttachmentTableViewCell = ComposeStatusAttachmentTableViewCell()
//    let composeStatusPollTableViewCell = ComposeStatusPollTableViewCell()
//
//    // var dataSource: UITableViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem>?
//    var customEmojiPickerDiffableDataSource: UICollectionViewDiffableDataSource<CustomEmojiPickerSection, CustomEmojiPickerItem>?
//    private(set) lazy var publishStateMachine: GKStateMachine = {
//        // exclude timeline middle fetcher state
//        let stateMachine = GKStateMachine(states: [
//            PublishState.Initial(viewModel: self),
//            PublishState.Publishing(viewModel: self),
//            PublishState.Fail(viewModel: self),
//            PublishState.Discard(viewModel: self),
//            PublishState.Finish(viewModel: self),
//        ])
//        stateMachine.enter(PublishState.Initial.self)
//        return stateMachine
//    }()
//    private(set) lazy var publishStateMachinePublisher = CurrentValueSubject<PublishState?, Never>(nil)
//    private(set) var publishDate = Date()   // update it when enter Publishing state
//
//    // TODO: group post material into Hashable class
//    var idempotencyKey = CurrentValueSubject<String, Never>(UUID().uuidString)
//
//    // UI & UX
//    @Published var title: String
//    @Published var shouldDismiss = true
//    @Published var isPublishBarButtonItemEnabled = false
//    @Published var isMediaToolbarButtonEnabled = true
//    @Published var isPollToolbarButtonEnabled = true
//    @Published var characterCount = 0
//    @Published var collectionViewState: CollectionViewState = .fold
//
//    // for hashtag: "#<hashtag> "
//    // for mention: "@<mention> "
//    var preInsertedContent: String?
//
//    // custom emojis
//    let customEmojiViewModel: EmojiService.CustomEmojiViewModel?
//    let customEmojiPickerInputViewModel = CustomEmojiPickerInputViewModel()
//    @Published var isLoadingCustomEmoji = false
//
//    // attachment
//    @Published var attachmentServices: [MastodonAttachmentService] = []
//
//    // polls
//    @Published var pollOptionAttributes: [ComposeStatusPollItem.PollOptionAttribute] = []
//    let pollExpiresOptionAttribute = ComposeStatusPollItem.PollExpiresOptionAttribute()
    
    init(
        context: AppContext,
        authContext: AuthContext,
        kind: ComposeContentViewModel.Kind
    ) {
        self.context = context
        self.authContext = authContext
        self.kind = kind
        
//        self.title = {
//            switch composeKind {
//            case .post, .hashtag, .mention:       return L10n.Scene.Compose.Title.newPost
//            case .reply:                          return L10n.Scene.Compose.Title.newReply
//            }
//        }()
//        self.selectedStatusVisibility = {
//            // default private when user locked
//            var visibility: ComposeToolbarView.VisibilitySelectionType = {
//                guard let author = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: context.managedObjectContext)?.user
//                else {
//                    return .public
//                }
//                return author.locked ? .private : .public
//            }()
//            // set visibility for reply post
//            switch composeKind {
//            case .reply(let record):
//                context.managedObjectContext.performAndWait {
//                    guard let status = record.object(in: context.managedObjectContext) else {
//                        assertionFailure()
//                        return
//                    }
//                    let repliedStatusVisibility = status.visibility
//                    switch repliedStatusVisibility {
//                    case .public, .unlisted:
//                        // keep default
//                        break
//                    case .private:
//                        visibility = .private
//                    case .direct:
//                        visibility = .direct
//                    case ._other:
//                        assertionFailure()
//                        break
//                    }
//                }
//            default:
//                break
//            }
//            return visibility
//        }()
//        // set limit
//        self.instanceConfiguration = {
//            var configuration: Mastodon.Entity.Instance.Configuration? = nil
//            context.managedObjectContext.performAndWait {
//                guard let authentication = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: context.managedObjectContext) else { return }
//                configuration = authentication.instance?.configuration
//            }
//            return configuration
//        }()
//        self.customEmojiViewModel = context.emojiService.dequeueCustomEmojiViewModel(for: authContext.mastodonAuthenticationBox.domain)
//        super.init()
//        // end init
//
//        setup(cell: composeStatusContentTableViewCell)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ComposeViewModel {
//    func createNewPollOptionIfPossible() {
//        guard pollOptionAttributes.count < maxPollOptions else { return }
//
//        let attribute = ComposeStatusPollItem.PollOptionAttribute()
//        pollOptionAttributes = pollOptionAttributes + [attribute]
//    }
//
//    func updatePublishDate() {
//        publishDate = Date()
//    }
}

//extension ComposeViewModel {
//
//    enum AttachmentPrecondition: Error, LocalizedError {
//        case videoAttachWithPhoto
//        case moreThanOneVideo
//
//        var errorDescription: String? {
//            return L10n.Common.Alerts.PublishPostFailure.title
//        }
//
//        var failureReason: String? {
//            switch self {
//            case .videoAttachWithPhoto:
//                return L10n.Common.Alerts.PublishPostFailure.AttachmentsMessage.videoAttachWithPhoto
//            case .moreThanOneVideo:
//                return L10n.Common.Alerts.PublishPostFailure.AttachmentsMessage.moreThanOneVideo
//            }
//        }
//    }
//
//    // check exclusive limit:
//    // - up to 1 video
//    // - up to N photos
//    func checkAttachmentPrecondition() throws {
//        let attachmentServices = self.attachmentServices
//        guard !attachmentServices.isEmpty else { return }
//        var photoAttachmentServices: [MastodonAttachmentService] = []
//        var videoAttachmentServices: [MastodonAttachmentService] = []
//        attachmentServices.forEach { service in
//            guard let file = service.file.value else {
//                assertionFailure()
//                return
//            }
//            switch file {
//            case .jpeg, .png, .gif:
//                photoAttachmentServices.append(service)
//            case .other:
//                videoAttachmentServices.append(service)
//            }
//        }
//
//        if !videoAttachmentServices.isEmpty {
//            guard videoAttachmentServices.count == 1 else {
//                throw AttachmentPrecondition.moreThanOneVideo
//            }
//            guard photoAttachmentServices.isEmpty else {
//                throw AttachmentPrecondition.videoAttachWithPhoto
//            }
//        }
//    }
//
//}
//
//// MARK: - MastodonAttachmentServiceDelegate
//extension ComposeViewModel: MastodonAttachmentServiceDelegate {
//    func mastodonAttachmentService(_ service: MastodonAttachmentService, uploadStateDidChange state: MastodonAttachmentService.UploadState?) {
//        // trigger new output event
//        attachmentServices = attachmentServices
//    }
//}
//
//// MARK: - ComposePollAttributeDelegate
//extension ComposeViewModel: ComposePollAttributeDelegate {
//    func composePollAttribute(_ attribute: ComposeStatusPollItem.PollOptionAttribute, pollOptionDidChange: String?) {
//        // trigger update
//        pollOptionAttributes = pollOptionAttributes
//    }
//}
//
//extension ComposeViewModel {
//    private func setup(
//        cell: ComposeStatusContentTableViewCell
//    ) {
//        setupStatusHeader(cell: cell)
//        setupStatusAuthor(cell: cell)
//        setupStatusContent(cell: cell)
//    }
//
//    private func setupStatusHeader(
//        cell: ComposeStatusContentTableViewCell
//    ) {
//        // configure header
//        let managedObjectContext = context.managedObjectContext
//        managedObjectContext.performAndWait {
//            guard case let .reply(record) = self.composeKind,
//                  let replyTo = record.object(in: managedObjectContext)
//            else {
//                cell.statusView.viewModel.header = .none
//                return
//            }
//
//            let info: StatusView.ViewModel.Header.ReplyInfo
//            do {
//                let content = MastodonContent(
//                    content: replyTo.author.displayNameWithFallback,
//                    emojis: replyTo.author.emojis.asDictionary
//                )
//                let metaContent = try MastodonMetaContent.convert(document: content)
//                info = .init(header: metaContent)
//            } catch {
//                let metaContent = PlaintextMetaContent(string: replyTo.author.displayNameWithFallback)
//                info = .init(header: metaContent)
//            }
//            cell.statusView.viewModel.header = .reply(info: info)
//        }
//    }
//
//    private func setupStatusAuthor(
//        cell: ComposeStatusContentTableViewCell
//    ) {
//        self.context.managedObjectContext.performAndWait {
//            guard let author = authenticationBox.authenticationRecord.object(in: self.context.managedObjectContext)?.user else { return }
//            cell.statusView.configureAuthor(author: author)
//        }
//    }
//
//    private func setupStatusContent(
//        cell: ComposeStatusContentTableViewCell
//    ) {
//        switch composeKind {
//        case .reply(let record):
//            context.managedObjectContext.performAndWait {
//                guard let status = record.object(in: context.managedObjectContext) else { return }
//                let author = self.authenticationBox.authenticationRecord.object(in: context.managedObjectContext)?.user
//
//                var mentionAccts: [String] = []
//                if author?.id != status.author.id {
//                    mentionAccts.append("@" + status.author.acct)
//                }
//                let mentions = status.mentions
//                    .filter { author?.id != $0.id }
//                for mention in mentions {
//                    let acct = "@" + mention.acct
//                    guard !mentionAccts.contains(acct) else { continue }
//                    mentionAccts.append(acct)
//                }
//                for acct in mentionAccts {
//                    UITextChecker.learnWord(acct)
//                }
//                if let spoilerText = status.spoilerText, !spoilerText.isEmpty {
//                    self.isContentWarningComposing = true
//                    self.composeStatusAttribute.contentWarningContent = spoilerText
//                }
//
//                let initialComposeContent = mentionAccts.joined(separator: " ")
//                let preInsertedContent: String? = initialComposeContent.isEmpty ? nil : initialComposeContent + " "
//                self.preInsertedContent = preInsertedContent
//                self.composeStatusAttribute.composeContent = preInsertedContent
//            }
//        case .hashtag(let hashtag):
//            let initialComposeContent = "#" + hashtag
//            UITextChecker.learnWord(initialComposeContent)
//            let preInsertedContent = initialComposeContent + " "
//            self.preInsertedContent = preInsertedContent
//            self.composeStatusAttribute.composeContent = preInsertedContent
//        case .mention(let record):
//            context.managedObjectContext.performAndWait {
//                guard let user = record.object(in: context.managedObjectContext) else { return }
//                let initialComposeContent = "@" + user.acct
//                UITextChecker.learnWord(initialComposeContent)
//                let preInsertedContent = initialComposeContent + " "
//                self.preInsertedContent = preInsertedContent
//                self.composeStatusAttribute.composeContent = preInsertedContent
//            }
//        case .post:
//            self.preInsertedContent = nil
//        }
//
//        // configure content warning
//        if let composeContent = composeStatusAttribute.composeContent {
//            cell.metaText.textView.text = composeContent
//        }
//
//        // configure content warning
//        cell.statusContentWarningEditorView.textView.text = composeStatusAttribute.contentWarningContent
//    }
//}
