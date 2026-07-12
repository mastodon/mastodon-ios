//
//  StatusView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-1-10.
//

import UIKit
import Combine
import CoreData // needed until StatusView is gone
import CoreDataStack  // needed until StatusView is gone
import Meta
import MastodonAsset
import MastodonCore
import MastodonCommon
import MastodonExtension
import MastodonLocalization
import MastodonSDK
import MastodonMeta

extension StatusView {
    public final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()
        public var objects = Set<MastodonStatus>()
        public var managedObjects = Set<NSManagedObject>()

        public var authenticationBox: MastodonAuthenticationBox?
        public var untranslatedStatus: Mastodon.Entity.Status?
        public var _originalStatus: MastodonStatus? {
            didSet {
                // Note: the originalStatus is created fresh every time, so never canceling this subscription is ok for now.
                _originalStatus?.$entity
                    .receive(on: DispatchQueue.main)
                    .sink(receiveValue: { status in
                        self.isBookmark = status.bookmarked == true
                        self.isMuting = status.muted == true
                    })
                    .store(in: &disposeBag)
            }
        }
        
        // Sensitive
        public var contentDisplayMode: StatusView.ContentDisplayMode = .neverConceal

        // Header
        @Published public var header: Header = .none
        
        // Author
        @Published public var authorAvatarImage: UIImage?
        @Published public var authorAvatarImageURL: URL?
        @Published public var authorName: MetaContent?
        @Published public var authorId: String?
        @Published public var authorUsername: String?
        
        @Published public var locked = false
        
        @Published public var isMyself = false
        @Published public var isMuting = false
        @Published public var isBlocking = false
        @Published public var isFollowed = false
        
        // Translation
        @Published public var isCurrentlyTranslating = false
        @Published public var translation: Mastodon.Entity.Translation? = nil

        @Published public var timestamp: Date?
        public var timestampFormatter: ((_ date: Date, _ isEdited: Bool) -> String)?
        @Published public var timestampText = ""
        @Published public var applicationName: String? = nil
        
        // Spoiler
        @Published public var spoilerContent: MetaContent?
        
        // Status
        @Published public var content: MetaContent?
        @Published public var language: String?
        
        // Media
        @Published public var mediaViewConfigurations: [MediaView.Configuration] = []
        
        // Audio
        @Published public var audioConfigurations: [MediaView.Configuration] = []
        
        // Poll
        @Published public var pollItems: [PollItem] = []
        @Published public var selectedPollItems = IndexSet()  // when using .pollOption, selection information has to be stored separately.  deprecated .option wrapped that information inside the contained MastodonPollOption.
        @Published public var isVotable: Bool = false
        @Published public var isVoting: Bool = false
        @Published public var isVoteButtonEnabled: Bool = false
        @Published public var voterCount: Int?
        @Published public var voteCount = 0
        @Published public var expireAt: Date?
        @Published public var expired: Bool = false

        // Card
        @Published public var card: Mastodon.Entity.Card?

        // Visibility
        @Published public var visibility: MastodonVisibility = .public
        
        // Toolbar
        @Published public var isReblog: Bool = false
        @Published public var isReblogEnabled: Bool = true
        @Published public var isFavorite: Bool = false
        @Published public var isBookmark: Bool = false
        
        @Published public var replyCount: Int = 0
        @Published public var reblogCount: Int = 0
        @Published public var favoriteCount: Int = 0
        
        @Published public var editedAt: Date? = nil
        
        @Published public var groupedAccessibilityLabel = ""
        @Published public var contentAccessibilityLabel = ""

        let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()
        
        public enum Header {
            case none
            case directMention
            case reply(info: ReplyInfo, isDirectMessage: Bool)
            case repost(info: RepostInfo)
            // case notification(info: NotificationHeaderInfo)
            
            public class ReplyInfo {
                public let header: MetaContent
                
                public init(header: MetaContent) {
                    self.header = header
                }
            }
            
            public struct RepostInfo {
                public let header: MetaContent
                
                public init(header: MetaContent) {
                    self.header = header
                }
            }
        }
        
        public func prepareForReuse() {
            contentDisplayMode = .neverConceal
            authenticationBox = nil
            authorAvatarImageURL = nil
            isCurrentlyTranslating = false
            isBookmark = false
            translation = nil
        }
        
        init() {
            // isReblogEnabled
            Publishers.CombineLatest(
                $visibility,
                $isMyself
            )
            .map { visibility, isMyself in
                switch visibility {
                case .public, .unlisted, ._other:
                    return true
                case .private where isMyself:
                    return true
                case .private, .direct:
                    return false
                }
            }
            .assign(to: &$isReblogEnabled)
        }
    }
}

extension StatusView.ViewModel {
    
    func bind(statusView: StatusView) {
        bindHeader(statusView: statusView)
        bindAuthor(statusView: statusView)
        bindContent(statusView: statusView)
        bindMedia(statusView: statusView)
        bindPoll(statusView: statusView)
        bindCard(statusView: statusView)
        bindMetric(statusView: statusView)
        bindMenu(statusView: statusView)
        bindAccessibility(statusView: statusView)
    }
    
    private func bindHeader(statusView: StatusView) {
        $header
            .sink { header in
                switch header {
                case .none:
                    return
                case .repost(let info):
                    statusView.headerIconImageView.image = UIImage(systemName: "repeat")!.withRenderingMode(.alwaysTemplate)
                    statusView.headerInfoLabel.configure(content: info.header)
                    statusView.setHeaderDisplay()
                case let .reply(info, isDirect):
                    assert(Thread.isMainThread)
                    statusView.headerIconImageView.image = UIImage(systemName: "arrowshape.turn.up.left.fill")!.withRenderingMode(.alwaysTemplate)
                    if isDirect {
                        statusView.headerIconImageView.tintColor = Asset.Colors.accent.color
                        statusView.headerInfoLabel.setup(style: .statusHeader, fontColor: Asset.Colors.accent.color)
                    }
                    statusView.headerInfoLabel.configure(content: info.header)
                    statusView.setHeaderDisplay()
                case .directMention:
                    assert(Thread.isMainThread)
                    statusView.headerIconImageView.image = UIImage(systemName: "at")!.withRenderingMode(.alwaysTemplate)
                    statusView.headerIconImageView.tintColor = Asset.Colors.accent.color
                    statusView.headerInfoLabel.setup(style: .statusHeader, fontColor: Asset.Colors.accent.color)
                    statusView.headerInfoLabel.configure(content: PlaintextMetaContent(string: L10n.Common.Controls.Status.privateMention))
                    statusView.setHeaderDisplay()
                }
            }
            .store(in: &disposeBag)
    }
    
    private func bindAuthor(statusView: StatusView) {
        let authorView = statusView.authorView
        // avatar
        $authorAvatarImageURL.removeDuplicates()
        .sink { url in
            authorView.avatarButton.avatarImageView.configure(with: url)
            authorView.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 12)))
        }
        .store(in: &disposeBag)
        // visibility
        $visibility
            .sink { visibility in
                authorView.visibilityIcon.image = visibility.image
                switch visibility {
                case .public, ._other:
                    authorView.visibilityIcon.isHidden = true
                case .direct, .private, .unlisted:
                    authorView.visibilityIcon.isHidden = false
                }
            }
            .store(in: &disposeBag)
        // name
        $authorName
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: " ")
                authorView.authorNameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // username
        $authorUsername
            .map { text -> String in
                guard let text = text else { return "" }
                return "@\(text)"
            }
            .sink { username in
                let metaContent = PlaintextMetaContent(string: username)
                authorView.authorUsernameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // timestamp
        Publishers.CombineLatest3(
            $timestamp,
            $editedAt.removeDuplicates(),
            timestampUpdatePublisher.prepend(Date()).eraseToAnyPublisher()
        )
        .sink(receiveValue: { [weak self] timestamp, editedAt, _ in
            guard let self = self else { return }
            if let timestamp = editedAt, let text = self.timestampFormatter?(timestamp, true) {
                self.editedAt = editedAt
                timestampText = text
            } else if let timestamp = timestamp, let text = self.timestampFormatter?(timestamp, false) {
                timestampText = text
            }
        })
        .store(in: &disposeBag)

        $timestampText
            .sink { text in
                authorView.dateLabel.configure(content: PlaintextMetaContent(string: text))
            }
            .store(in: &disposeBag)
    }
    
    private func bindContent(statusView: StatusView) {
        Publishers.CombineLatest3(
            $spoilerContent,
            $content,
            $language
        )
        .sink { spoilerContent, content, language in
            
            if statusView.style == .editHistory {
                statusView.setContentSensitiveeToggleButtonDisplay(isDisplay: false)
            }
            
            let paragraphStyle = statusView.contentMetaText.paragraphStyle
            if let language = language { 
                let direction = Locale.Language(identifier: language).characterDirection
                paragraphStyle.alignment = direction == .rightToLeft ? .right : .left
            } else {
                paragraphStyle.alignment = .natural
            }
            statusView.contentMetaText.paragraphStyle = paragraphStyle
            
            if let content = content, !(content.string.isEmpty && content.entities.isEmpty) {
                statusView.contentMetaText.configure(
                    content: content
                )
                statusView.contentMetaText.textView.accessibilityTraits = [.staticText]
                statusView.contentMetaText.textView.accessibilityElementsHidden = false
                statusView.contentMetaText.textView.isHidden = false

            } else {
                statusView.contentMetaText.reset()
                statusView.contentMetaText.textView.accessibilityLabel = ""
                statusView.contentMetaText.textView.isHidden = true
            }
        }
        .store(in: &disposeBag)

        $isCurrentlyTranslating
            .receive(on: DispatchQueue.main)
            .sink { isTranslating in
                switch isTranslating {
                case true:
                    statusView.isTranslatingLoadingView.startAnimating()
                case false:
                    statusView.isTranslatingLoadingView.stopAnimating()
                }
            }
            .store(in: &disposeBag)
    }
    
    private func bindMedia(statusView: StatusView) {
        $mediaViewConfigurations
            .sink { configurations in
                statusView.mediaGridContainerView.prepareForReuse()
                
                let maxSize = CGSize(
                    width: statusView.contentMaxLayoutWidth,
                    height: statusView.contentMaxLayoutHeight
                )
                var needsDisplay = true
                switch configurations.count {
                case 0:
                    needsDisplay = false
                case 1:
                    let configuration = configurations[0]
                    let adaptiveLayout = MediaGridContainerView.AdaptiveLayout(
                        aspectRatio: configuration.aspectRadio,
                        maxSize: maxSize
                    )
                    let mediaView = statusView.mediaGridContainerView.dequeueMediaView(adaptiveLayout: adaptiveLayout)
                    mediaView.setup(configuration: configuration)
                default:
                    let gridLayout = MediaGridContainerView.GridLayout(
                        count: configurations.count,
                        maxSize: maxSize
                    )
                    let mediaViews = statusView.mediaGridContainerView.dequeueMediaView(gridLayout: gridLayout)
                    for (i, (configuration, mediaView)) in zip(configurations, mediaViews).enumerated() {
                        guard i < MediaGridContainerView.maxCount else { break }
                        mediaView.setup(configuration: configuration)
                    }
                }
                if needsDisplay {
                    statusView.setMediaDisplay()
                }
            }
            .store(in: &disposeBag)
    }
    
    private func bindPoll(statusView: StatusView) {
        $pollItems
            .sink { items in
                guard !items.isEmpty else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<PollSection, PollItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items, toSection: .main)
                statusView.pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(snapshot)
                
                statusView.pollTableViewHeightLayoutConstraint.constant = CGFloat(items.count) * PollOptionTableViewCell.height
                statusView.setPollDisplay()
                
                items.forEach({ item in
                    guard case let PollItem.option(record) = item else { return }
                    record.$isSelected.receive(on: DispatchQueue.main).sink { [weak self] selected in
                        guard let self else { return }
                        if (selected) {
                            // as we have just selected an option, the vote button must be enabled
                            self.isVoteButtonEnabled = true
                        } else {
                            // figure out which buttons are currently selected
                            let records = pollItems.compactMap({ item -> MastodonPollOption? in
                                guard case let PollItem.option(record) = item else { return nil }
                                return record
                            })
                            .filter({ $0.isSelected })
                            
                            // only enable vote button if there are selected options
                            self.isVoteButtonEnabled = !records.isEmpty
                        }
                        statusView.pollTableView.reloadData()
                    }
                    .store(in: &self.disposeBag)
                })
            }
            .store(in: &disposeBag)

        $isVotable
            .sink { isVotable in
                statusView.pollTableView.allowsSelection = isVotable
            }
            .store(in: &disposeBag)
        // poll
        let pollVoteDescription = Publishers.CombineLatest(
            $voterCount,
            $voteCount
        )
        .map { voterCount, voteCount -> String in
            var description = ""
            if let voterCount = voterCount {
                description += L10n.Plural.Count.voter(voterCount)
            } else {
                description += L10n.Plural.Count.vote(voteCount)
            }
            return description
        }
        let pollCountdownDescription = Publishers.CombineLatest3(
            $expireAt,
            $expired,
            timestampUpdatePublisher.prepend(Date()).eraseToAnyPublisher()
        )
        .map { expireAt, expired, _ -> String? in
            guard !expired else {
                return L10n.Common.Controls.Status.Poll.closed
            }
            
            guard let expireAt = expireAt else {
                return nil
            }
            let timeLeft = expireAt.localizedTimeLeft()
            
            return timeLeft
        }
        Publishers.CombineLatest(
            pollVoteDescription,
            pollCountdownDescription
        )
        .sink { pollVoteDescription, pollCountdownDescription in
            statusView.pollVoteCountLabel.text = pollVoteDescription
            statusView.pollCountdownLabel.text = pollCountdownDescription ?? "-"
        }
        .store(in: &disposeBag)
        Publishers.CombineLatest(
            $isVotable,
            $isVoting
        )
        .receive(on: DispatchQueue.main)
        .sink { isVotable, isVoting in
            guard isVotable else {
                statusView.pollVoteButton.isHidden = true
                statusView.pollVoteActivityIndicatorView.isHidden = true
                statusView.pollTableView.isUserInteractionEnabled = false
                return
            }

            statusView.pollVoteButton.isHidden = isVoting
            statusView.pollTableView.isUserInteractionEnabled = !isVoting
            statusView.pollVoteActivityIndicatorView.isHidden = !isVoting
            statusView.pollVoteActivityIndicatorView.startAnimating()
        }
        .store(in: &disposeBag)
        $isVoteButtonEnabled
            .assign(to: \.isEnabled, on: statusView.pollVoteButton)
            .store(in: &disposeBag)
    }

    private func bindCard(statusView: StatusView) {
        $card.sink { card in
            guard let card = card else { return }
            statusView.statusCardControl.configure(card: card)
            statusView.setStatusCardControlDisplay()
        }
        .store(in: &disposeBag)
    }
    
    private func bindMetric(statusView: StatusView) {
        let reblogButtonTitle = $reblogCount.map { count in
            L10n.Plural.Count.reblog(count)
        }.share()
        
        let favoriteButtonTitle = $favoriteCount.map { count in
            L10n.Plural.Count.favorite(count)
        }.share()
        
        
        let metricButtonTitleLength = Publishers.CombineLatest(
            reblogButtonTitle,
            favoriteButtonTitle
        ).map { $0.count + $1.count }
        
        Publishers.CombineLatest3(
            $timestamp,
            $applicationName,
            metricButtonTitleLength
        )
        .sink { timestamp, applicationName, metricButtonTitleLength in
            let dateString: String = {
                guard let timestamp = timestamp else { return " " }
                
                let formatter = DateFormatter()
                
                // make adaptive UI
                if UIView.isZoomedMode || metricButtonTitleLength > 20 {
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                } else {
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                }
                return formatter.string(from: timestamp)
            }()

            let text: String
            if let applicationName {
                text = L10n.Common.Controls.Status.postedViaApplication(dateString, applicationName)
            } else {
                text = dateString
            }

            statusView.statusMetricView.dateLabel.text = text
        }
        .store(in: &disposeBag)
        
        $reblogCount
            .sink { count in
                statusView.statusMetricView.reblogButton.isHidden = count == 0
                statusView.statusMetricView.reblogButton.detailLabel.text = count.formatted()
            }
            .store(in: &disposeBag)
        
        $favoriteCount
            .sink { count in
                statusView.statusMetricView.favoriteButton.isHidden = count == 0
                statusView.statusMetricView.favoriteButton.detailLabel.text = count.formatted()
            }
            .store(in: &disposeBag)

        $editedAt
            .sink { editedAt in
                if let editedAt {
                    let relativeDateFormatter = RelativeDateTimeFormatter()
                    let relativeDate = relativeDateFormatter.localizedString(for: editedAt, relativeTo: Date())
                    statusView.statusMetricView.editHistoryButton.detailLabel.text = L10n.Common.Controls.Status.Buttons.editHistoryDetail(relativeDate)
                    statusView.statusMetricView.editHistoryButton.isHidden = false
                } else {
                    statusView.statusMetricView.editHistoryButton.isHidden = true
                }
            }
            .store(in: &disposeBag)
    }
    
    private func bindMenu(statusView: StatusView) {
        let authorView = statusView.authorView
        let publisherOne = Publishers.CombineLatest3(
            $authorName,
            $authorId,
            $isMyself
        )

        let publishersThree = Publishers.CombineLatest(
            $translation,
            $language
        )

        let publisherTwo = Publishers.CombineLatest3(
            $isBookmark, $isFavorite, $isReblog
        )

        Publishers.CombineLatest3(
            publisherOne.eraseToAnyPublisher(),
            publisherTwo.eraseToAnyPublisher(),
            publishersThree.eraseToAnyPublisher()
        ).eraseToAnyPublisher()
            .sink { tupleOne, tupleTwo, tupleThree in
                let (authorName, authorId, isMyself) = tupleOne
                let (isBookmark, isFavorite, isBoosted) = tupleTwo
                let (translatedFromLanguage, language) = tupleThree

                guard let name = authorName?.string, let authorId = authorId, let authenticationBox = self.authenticationBox else {
                    statusView.authorView.menuButton.menu = nil
                    return
                }

                let isTranslationEnabled: Bool = {
                    guard let language, let targetLanguage = Bundle.main.preferredLocalizations.first else { return false }
                    return authenticationBox.authentication.instanceConfiguration?.canTranslateFrom(
                        language,
                        to: targetLanguage
                    ) ?? false
                }()

                authorView.menuButton.menu = UIMenu(children: [
                    UIDeferredMenuElement.uncached({ menuElement in

                        let domain = authenticationBox.domain

                        Task { @MainActor in
                            if let relationship = try? await Mastodon.API.Account.relationships(
                                session: .shared,
                                domain: domain,
                                query: .init(ids: [authorId]),
                                authorization: authenticationBox.userAuthorization
                            ).singleOutput().value {
                                guard let rel = relationship.first else { return }
                                DispatchQueue.main.async {

                                    let menuContext = StatusAuthorView.AuthorMenuContext(
                                        name: name,
                                        isMuting: rel.muting,
                                        isBlocking: rel.blocking,
                                        isMyself: isMyself,
                                        isBookmarked: isBookmark,
                                        isFollowed: rel.following,
                                        isTranslationEnabled: isTranslationEnabled,
                                        isTranslated: translatedFromLanguage != nil,
                                        statusLanguage: language,
                                        isFavorited: isFavorite,
                                        isBoosted: isBoosted
                                    )
                                
                                    let (menu, actions) = authorView.setupAuthorMenu(menuContext: menuContext)
                                    authorView.authorActions = actions
                                    
                                    menuElement(menu.children)
                                }
                            } else {
                                menuElement(
                                    MastodonMenu.setupMenu(
                                        submenus: [MastodonMenu.Submenu(actions: [.shareStatus])],
                                        delegate: statusView).children
                                )
                            }
                        }
                    })
                ])
                                
                authorView.menuButton.showsMenuAsPrimaryAction = true
            }
            .store(in: &disposeBag)
    }
    
    private func bindAccessibility(statusView: StatusView) {
        let shortAuthorAccessibilityLabel = Publishers.CombineLatest4(
            $header,
            $authorName,
            $authorUsername,
            $timestampText
        )
        .map { header, authorName, authorUsername, timestamp -> String? in
            var strings: [String?] = []
            
            switch header {
            case .none:
                strings.append(authorName?.string)
                strings.append(authorUsername)
            case .directMention:
                strings.append(L10n.Common.Controls.Status.privateMention)
                strings.append(authorName?.string)
                strings.append(authorUsername)
            case .reply(let info, _):
                strings.append(authorName?.string)
                strings.append(authorUsername)
                strings.append(info.header.string)
            case .repost(let info):
                strings.append(info.header.string)
                strings.append(authorName?.string)
                strings.append(authorUsername)
            }

            if statusView.style != .editHistory {
                strings.append(timestamp)
            }
            
            return strings.compactMap { $0 }.joined(separator: ", ")
        }

        let longTimestampFormatter = DateFormatter()
        longTimestampFormatter.dateStyle = .medium
        longTimestampFormatter.timeStyle = .short
        let longTimestampLabel = Publishers.CombineLatest(
            $timestampText,
            $timestamp.map { timestamp in
                if let timestamp {
                    return longTimestampFormatter.string(from: timestamp)
                }
                return ""
            }
        )
            .map { timestampText, longTimestamp in
                "\(timestampText). \(longTimestamp)"
            }

        Publishers.CombineLatest4(
            $header,
            $authorName,
            $authorUsername,
            longTimestampLabel
        )
        .map { header, name, username, timestamp in
            let nameAndUsername = "\(name?.string ?? "") @\(username ?? "")"
            switch header {
            case .none:
                return "\(nameAndUsername), \(timestamp)"
            case .directMention:
                return "\(L10n.Common.Controls.Status.privateMention) \(nameAndUsername), \(timestamp)"
            case .repost(info: let info):
                return "\(info.header.string) \(nameAndUsername), \(timestamp)"
            case let .reply(info, _):
                return "\(nameAndUsername) \(info.header.string), \(timestamp)"
            }
        }
        .assign(to: \.accessibilityLabel, on: statusView.authorView)
        .store(in: &disposeBag)

        Publishers.CombineLatest(
            $spoilerContent,
            $content
        )
        .map { [weak self] spoilerContent, content in
            guard let self else { return "" }
            
            var strings: [String?] = []
            
            if let spoilerContent = spoilerContent, !spoilerContent.string.isEmpty {
                strings.append(L10n.Common.Controls.Status.contentWarning)
                strings.append(spoilerContent.string)
                
                strings.append(L10n.Common.Controls.Status.mediaContentWarning)
            }

            if !self.contentDisplayMode.shouldConcealText {
                strings.append(content?.string)
            }
            
            return strings.compactMap { $0 }.joined(separator: ", ")
        }
        .assign(to: &$contentAccessibilityLabel)
        
        $contentAccessibilityLabel
            .sink { contentAccessibilityLabel in
                statusView.contentConcealExplainView.accessibilityLabel = contentAccessibilityLabel
            }
            .store(in: &disposeBag)

        let mediaAccessibilityLabel = $mediaViewConfigurations
            .map { configurations -> String? in
                let count = configurations.count
                return L10n.Plural.Count.media(count)
            }
            
        let translatedFromLabel = $translation
            .map { translation -> String? in
                guard let translation else { return nil }

                let provider = translation.provider ?? L10n.Common.Controls.Status.Translation.unknownProvider
                let sourceLanguage: String

                if let language = translation.sourceLanguage {
                    sourceLanguage = Locale.current.localizedString(forIdentifier: language) ?? L10n.Common.Controls.Status.Translation.unknownLanguage
                } else {
                    sourceLanguage = L10n.Common.Controls.Status.Translation.unknownLanguage
                }

                return L10n.Common.Controls.Status.Translation.translatedFrom(sourceLanguage, provider)
            }

        translatedFromLabel
            .receive(on: DispatchQueue.main)
            .sink { label in
                if let label {
                    statusView.translatedInfoLabel.text = label
                    statusView.translatedInfoView.accessibilityValue = label
                    statusView.translatedInfoView.isHidden = false
                } else {
                    statusView.translatedInfoView.isHidden = true
                }
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest4(
            shortAuthorAccessibilityLabel,
            $contentAccessibilityLabel,
            translatedFromLabel,
            mediaAccessibilityLabel
        )
        .map { author, content, translated, media in
            var labels: [String?] = [content, translated, media]

            if statusView.style != .notification {
                labels.insert(author, at: 0)
            }

            return labels
                .compactMap { $0 }
                .joined(separator: ", ")
        }
        .assign(to: &$groupedAccessibilityLabel)
        
        $groupedAccessibilityLabel
            .sink { accessibilityLabel in
                statusView.accessibilityLabel = accessibilityLabel
            }
            .store(in: &disposeBag)

        $content
        .map { [weak self] content in
            guard let self, !self.contentDisplayMode.shouldConcealText, let entities = content?.entities else { return [] }
            return entities.compactMap { entity in
                guard let name = entity.meta.accessibilityLabel else { return nil }
                return UIAccessibilityCustomAction(name: name) { action in
                    statusView.delegate?.statusView(statusView, metaText: statusView.contentMetaText, didSelectMeta: entity.meta)
                    return true
                }
            }
        }
        .assign(to: \.accessibilityCustomActions, on: statusView.contentMetaText.textView)
        .store(in: &disposeBag)
    }
    
}
