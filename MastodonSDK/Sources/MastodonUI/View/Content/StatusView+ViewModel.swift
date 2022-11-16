//
//  StatusView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-1-10.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import Meta
import MastodonAsset
import MastodonCore
import MastodonCommon
import MastodonExtension
import MastodonLocalization
import MastodonSDK

extension StatusView {
    public final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()
        public var objects = Set<NSManagedObject>()

        let logger = Logger(subsystem: "StatusView", category: "ViewModel")
        
        public var authContext: AuthContext?
        
        // Header
        @Published public var header: Header = .none
        
        // Author
        @Published public var authorAvatarImage: UIImage?
        @Published public var authorAvatarImageURL: URL?
        @Published public var authorName: MetaContent?
        @Published public var authorUsername: String?
        
        @Published public var locked = false
        
        @Published public var isMyself = false
        @Published public var isMuting = false
        @Published public var isBlocking = false
        
        @Published public var timestamp: Date?
        public var timestampFormatter: ((_ date: Date) -> String)?
        @Published public var timestampText = ""
        
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
        @Published public var isVotable: Bool = false
        @Published public var isVoting: Bool = false
        @Published public var isVoteButtonEnabled: Bool = false
        @Published public var voterCount: Int?
        @Published public var voteCount = 0
        @Published public var expireAt: Date?
        @Published public var expired: Bool = false
        
        // Visibility
        @Published public var visibility: MastodonVisibility = .public
        
        // Sensitive
        @Published public var isContentSensitive: Bool = false
        @Published public var isMediaSensitive: Bool = false
        @Published public var isSensitiveToggled = false
        
        @Published public var isContentReveal: Bool = true
        @Published public var isMediaReveal: Bool = true
        
        // Toolbar
        @Published public var isReblog: Bool = false
        @Published public var isReblogEnabled: Bool = true
        @Published public var isFavorite: Bool = false
        @Published public var isBookmark: Bool = false
        
        @Published public var replyCount: Int = 0
        @Published public var reblogCount: Int = 0
        @Published public var favoriteCount: Int = 0
        
        // Filter
        @Published public var activeFilters: [Mastodon.Entity.Filter] = []
        @Published public var filterContext: Mastodon.Entity.Filter.Context?
        @Published public var isFiltered = false

        @Published public var groupedAccessibilityLabel = ""

        let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()
        
        public enum Header {
            case none
            case reply(info: ReplyInfo)
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
            authContext = nil
            
            authorAvatarImageURL = nil
            
            isContentSensitive = false
            isMediaSensitive = false
            isSensitiveToggled = false
            
            activeFilters = []
            filterContext = nil
        }
        
        init() {
            // isReblogEnabled
            Publishers.CombineLatest(
                $visibility,
                $isMyself
            )
            .map { visibility, isMyself in
                if isMyself {
                    return true
                }
                
                switch visibility {
                case .public, .unlisted:
                    return true
                case .private, .direct, ._other:
                    return false
                }
            }
            .assign(to: &$isReblogEnabled)
            // isContentSensitive
            $spoilerContent
                .map { $0 != nil }
                .assign(to: &$isContentSensitive)
            // isReveal
            Publishers.CombineLatest3(
                $isContentSensitive,
                $isMediaSensitive,
                $isSensitiveToggled
            )
            .sink { [weak self] isContentSensitive, isMediaSensitive, isSensitiveToggled in
                guard let self = self else { return }
                self.isContentReveal = isContentSensitive ? isSensitiveToggled : true
                self.isMediaReveal = isMediaSensitive ? isSensitiveToggled : true
            }
            .store(in: &disposeBag)
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
        bindToolbar(statusView: statusView)
        bindMetric(statusView: statusView)
        bindMenu(statusView: statusView)
        bindFilter(statusView: statusView)
        bindAccessibility(statusView: statusView)
    }
    
    private func bindHeader(statusView: StatusView) {
        $header
            .sink { header in
                switch header {
                case .none:
                    return
                case .repost(let info):
                    statusView.headerIconImageView.image = Asset.Arrow.repeatSmall.image.withRenderingMode(.alwaysTemplate)
                    statusView.headerInfoLabel.configure(content: info.header)
                    statusView.setHeaderDisplay()
                case .reply(let info):
                    assert(Thread.isMainThread)
                    statusView.headerIconImageView.image = UIImage(systemName: "arrowshape.turn.up.left.fill")
                    statusView.headerInfoLabel.configure(content: info.header)
                    statusView.setHeaderDisplay()
                }
            }
            .store(in: &disposeBag)
    }
    
    private func bindAuthor(statusView: StatusView) {
        let authorView = statusView.authorView
        // avatar
        Publishers.CombineLatest(
            $authorAvatarImage.removeDuplicates(),
            $authorAvatarImageURL.removeDuplicates()
        )
        .sink { image, url in
            let configuration: AvatarImageView.Configuration = {
                if let image = image {
                    return AvatarImageView.Configuration(image: image)
                } else {
                    return AvatarImageView.Configuration(url: url)
                }
            }()
            authorView.avatarButton.avatarImageView.configure(configuration: configuration)
            authorView.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .fixed(radius: 12)))
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
        let usernamePublisher = $authorUsername
            .map { text -> String in
                guard let text = text else { return "" }
                return "@\(text)"
            }
        usernamePublisher
            .sink { username in
                let metaContent = PlaintextMetaContent(string: username)
                authorView.authorUsernameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // timestamp
        Publishers.CombineLatest(
            $timestamp,
            timestampUpdatePublisher.prepend(Date()).eraseToAnyPublisher()
        )
        .compactMap { [weak self] timestamp, _ -> String? in
            guard let self = self else { return nil }
            guard let timestamp = timestamp,
                  let text = self.timestampFormatter?(timestamp)
            else { return "" }
            return text
        }
        .removeDuplicates()
        .assign(to: &$timestampText)
        
        $timestampText
            .sink { [weak self] text in
                guard let _ = self else { return }
                authorView.dateLabel.configure(content: PlaintextMetaContent(string: text))
            }
            .store(in: &disposeBag)

        // accessibility label
        Publishers.CombineLatest4($authorName, usernamePublisher, $timestampText, $timestamp)
            .map { name, username, timestampText, timestamp in
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                let longTimestamp = timestamp.map { formatter.string(from: $0) } ?? ""
                return "\(name?.string ?? "") \(username), \(timestampText). \(longTimestamp)"
            }
            .assign(to: \.accessibilityLabel, on: authorView)
            .store(in: &disposeBag)
    }
    
    private func bindContent(statusView: StatusView) {
        Publishers.CombineLatest4(
            $spoilerContent,
            $content,
            $language,
            $isContentReveal.removeDuplicates()
        )
        .sink { spoilerContent, content, language, isContentReveal in
            if let spoilerContent = spoilerContent {
                statusView.spoilerOverlayView.spoilerMetaLabel.configure(content: spoilerContent)
                // statusView.spoilerBannerView.label.configure(content: spoilerContent)
                // statusView.setSpoilerBannerViewHidden(isHidden: !isContentReveal)

            } else {
                statusView.spoilerOverlayView.spoilerMetaLabel.reset()
                // statusView.spoilerBannerView.label.reset()
            }
            
            let paragraphStyle = statusView.contentMetaText.paragraphStyle
            if let language = language {
                let direction = Locale.characterDirection(forLanguage: language)
                paragraphStyle.alignment = direction == .rightToLeft ? .right : .left
            } else {
                paragraphStyle.alignment = .natural
            }
            statusView.contentMetaText.paragraphStyle = paragraphStyle
            
            if let content = content {
                statusView.contentMetaText.configure(
                    content: content
                )
                statusView.contentMetaText.textView.accessibilityTraits = [.staticText]
                statusView.contentMetaText.textView.accessibilityElementsHidden = false
            } else {
                statusView.contentMetaText.reset()
                statusView.contentMetaText.textView.accessibilityLabel = ""
            }
            
            statusView.contentMetaText.textView.alpha = isContentReveal ? 1 : 0     // keep the frame size and only display when revealing
            
            statusView.setSpoilerOverlayViewHidden(isHidden: isContentReveal)
            
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): isContentReveal: \(isContentReveal)")
        }
        .store(in: &disposeBag)

        $isMediaSensitive
            .sink { isSensitive in
                guard isSensitive else { return }
                statusView.setContentSensitiveeToggleButtonDisplay()
            }
            .store(in: &disposeBag)
        
        $isSensitiveToggled
            .sink { isSensitiveToggled in
                // The button indicator go-to state for button action direction
                // eye: when media is hidden
                // eye-slash: when media display
                let image = isSensitiveToggled ? UIImage(systemName: "eye.slash.fill") : UIImage(systemName: "eye.fill")
                statusView.authorView.contentSensitiveeToggleButton.setImage(image, for: .normal)
            }
            .store(in: &disposeBag)
    }
    
    private func bindMedia(statusView: StatusView) {
        $mediaViewConfigurations
            .sink { [weak self] configurations in
                guard let self = self else { return }
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): configure media")
                
                statusView.mediaGridContainerView.prepareForReuse()
                
                let maxSize = CGSize(
                    width: statusView.contentMaxLayoutWidth,
                    height: 9999        // fulfill the width
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
        
        Publishers.CombineLatest(
            $mediaViewConfigurations,
            $isMediaReveal
        )
        .sink { configurations, isMediaReveal in
            for configuration in configurations {
                configuration.isReveal = isMediaReveal
            }
        }
        .store(in: &disposeBag)
        
        $isMediaReveal
            .sink { isMediaReveal in
                statusView.mediaGridContainerView.contentWarningOverlay.isHidden = isMediaReveal
                statusView.mediaGridContainerView.viewModel.isSensitiveToggleButtonDisplay = isMediaReveal
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
                if #available(iOS 15.0, *) {
                    statusView.pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(snapshot)
                } else {
                    // Fallback on earlier versions
                    statusView.pollTableViewDiffableDataSource?.apply(snapshot, animatingDifferences: false)
                }
                
                statusView.pollTableViewHeightLayoutConstraint.constant = CGFloat(items.count) * PollOptionTableViewCell.height
                statusView.setPollDisplay()
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
            statusView.pollVoteCountLabel.text = pollVoteDescription ?? "-"
            statusView.pollCountdownLabel.text = pollCountdownDescription ?? "-"
        }
        .store(in: &disposeBag)
        Publishers.CombineLatest(
            $isVotable,
            $isVoting
        )
        .sink { isVotable, isVoting in
            guard isVotable else {
                statusView.pollVoteButton.isHidden = true
                statusView.pollVoteActivityIndicatorView.isHidden = true
                return
            }

            statusView.pollVoteButton.isHidden = isVoting
            statusView.pollVoteActivityIndicatorView.isHidden = !isVoting
            statusView.pollVoteActivityIndicatorView.startAnimating()
        }
        .store(in: &disposeBag)
        $isVoteButtonEnabled
            .assign(to: \.isEnabled, on: statusView.pollVoteButton)
            .store(in: &disposeBag)
    }
    
    private func bindToolbar(statusView: StatusView) {
        $replyCount
            .sink { count in
                statusView.actionToolbarContainer.configureReply(
                    count: count,
                    isEnabled: true
                )
            }
            .store(in: &disposeBag)
        Publishers.CombineLatest3(
            $reblogCount,
            $isReblog,
            $isReblogEnabled
        )
        .sink { count, isHighlighted, isEnabled in
            statusView.actionToolbarContainer.configureReblog(
                count: count,
                isEnabled: isEnabled,
                isHighlighted: isHighlighted
            )
        }
        .store(in: &disposeBag)
        Publishers.CombineLatest(
            $favoriteCount,
            $isFavorite
        )
        .sink { count, isHighlighted in
            statusView.actionToolbarContainer.configureFavorite(
                count: count,
                isEnabled: true,
                isHighlighted: isHighlighted
            )
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
        
        Publishers.CombineLatest(
            $timestamp,
            metricButtonTitleLength
        )
        .sink { timestamp, metricButtonTitleLength in
            let text: String = {
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
            
            statusView.statusMetricView.dateLabel.text = text
        }
        .store(in: &disposeBag)
        
        reblogButtonTitle
            .sink { title in
                statusView.statusMetricView.reblogButton.setTitle(title, for: .normal)
            }
            .store(in: &disposeBag)
        
        favoriteButtonTitle
            .sink { title in
                statusView.statusMetricView.favoriteButton.setTitle(title, for: .normal)
            }
            .store(in: &disposeBag)
    }
    
    private func bindMenu(statusView: StatusView) {
        let authorView = statusView.authorView
        let publisherOne = Publishers.CombineLatest(
            $authorName,
            $isMyself
        )
        let publishersTwo = Publishers.CombineLatest3(
            $isMuting,
            $isBlocking,
            $isBookmark
        )
        
        Publishers.CombineLatest(
            publisherOne.eraseToAnyPublisher(),
            publishersTwo.eraseToAnyPublisher()
        ).eraseToAnyPublisher()
        .sink { tupleOne, tupleTwo in
            let (authorName, isMyself) = tupleOne
            let (isMuting, isBlocking, isBookmark) = tupleTwo
            
            guard let name = authorName?.string else {
                statusView.authorView.menuButton.menu = nil
                return
            }
            
            let menuContext = StatusAuthorView.AuthorMenuContext(
                name: name,
                isMuting: isMuting,
                isBlocking: isBlocking,
                isMyself: isMyself,
                isBookmarking: isBookmark
            )
            let (menu, actions) = authorView.setupAuthorMenu(menuContext: menuContext)
            authorView.menuButton.menu = menu
            authorView.authorActions = actions
            authorView.menuButton.showsMenuAsPrimaryAction = true
        }
        .store(in: &disposeBag)
    }
    
    private func bindFilter(statusView: StatusView) {
        $isFiltered
            .sink { isFiltered in
                statusView.containerStackView.isHidden = isFiltered
                if isFiltered {
                    statusView.setFilterHintLabelDisplay()                    
                }
            }
            .store(in: &disposeBag)
    }
    
    private func bindAccessibility(statusView: StatusView) {
        let authorAccessibilityLabel = Publishers.CombineLatest3(
            $header,
            $authorName,
            $timestampText
        )
        .map { header, authorName, timestamp -> String? in
            var strings: [String?] = []
            
            switch header {
            case .none:
                break
            case .reply(let info):
                strings.append(info.header.string)
            case .repost(let info):
                strings.append(info.header.string)
            }
            
            strings.append(authorName?.string)
            strings.append(timestamp)
            
            return strings.compactMap { $0 }.joined(separator: ", ")
        }
        
        let contentAccessibilityLabel = Publishers.CombineLatest3(
            $isContentReveal,
            $spoilerContent,
            $content
        )
        .map { isContentReveal, spoilerContent, content -> String? in
            var strings: [String?] = []
            
            if let spoilerContent = spoilerContent, !spoilerContent.string.isEmpty {
                strings.append(L10n.Common.Controls.Status.contentWarning)
                strings.append(spoilerContent.string)
                
                // TODO: replace with "Tap to reveal"
                strings.append(L10n.Common.Controls.Status.mediaContentWarning)
            }

            if isContentReveal {
                strings.append(content?.string)
            }
            
            return strings.compactMap { $0 }.joined(separator: ", ")
        }
        
        $isContentReveal
            .map { isContentReveal in
                isContentReveal ? L10n.Scene.Compose.Accessibility.enableContentWarning : L10n.Scene.Compose.Accessibility.disableContentWarning
            }
            .sink { label in
                statusView.authorView.contentSensitiveeToggleButton.accessibilityLabel = label
            }
            .store(in: &disposeBag)
        
        contentAccessibilityLabel
            .sink { contentAccessibilityLabel in
                statusView.spoilerOverlayView.accessibilityLabel = contentAccessibilityLabel
            }
            .store(in: &disposeBag)
        
        let meidaAccessibilityLabel = $mediaViewConfigurations
            .map { configurations -> String? in
                let count = configurations.count
                return L10n.Plural.Count.media(count)
            }
            
        // TODO: Toolbar
    
        Publishers.CombineLatest3(
            authorAccessibilityLabel,
            contentAccessibilityLabel,
            meidaAccessibilityLabel
        )
        .map { author, content, media in
            let group = [
                author,
                content,
                media
            ]
            
            return group
                .compactMap { $0 }
                .joined(separator: ", ")
        }
        .assign(to: &$groupedAccessibilityLabel)
        
        $groupedAccessibilityLabel
            .sink { accessibilityLabel in
                statusView.accessibilityLabel = accessibilityLabel
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest(
            $content,
            $isContentReveal.removeDuplicates()
        )
        .map { content, isRevealed in
            guard isRevealed, let entities = content?.entities else { return [] }
            return entities.compactMap { entity in
                guard let name = entity.accessibilityCustomActionLabel else { return nil }
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
