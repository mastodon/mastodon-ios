//
//  TimelineSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import Combine
import CoreData
import CoreDataStack
import os.log
import UIKit
import AVKit
import Nuke

#if ASDK
import AsyncDisplayKit
#endif

protocol StatusCell: DisposeBagCollectable {
    var statusView: StatusView { get }
}

enum StatusSection: Equatable, Hashable {
    case main
}

extension StatusSection {
    #if ASDK
    static func tableNodeDiffableDataSource(
        tableNode: ASTableNode,
        managedObjectContext: NSManagedObjectContext
    ) -> TableNodeDiffableDataSource<StatusSection, Item> {
        TableNodeDiffableDataSource(tableNode: tableNode) { tableNode, indexPath, item in
            switch item {
            case .homeTimelineIndex(let objectID, let attribute):
                guard let homeTimelineIndex = try? managedObjectContext.existingObject(with: objectID) as? HomeTimelineIndex else {
                    return { ASCellNode() }
                }
                let status = homeTimelineIndex.status

                return { () -> ASCellNode in
                    let cellNode = StatusNode(status: status)
                    return cellNode
                }
            case .homeMiddleLoader:
                return { TimelineMiddleLoaderNode() }
            case .bottomLoader:
                return { TimelineBottomLoaderNode() }
            default:
                return { ASCellNode() }
            }
        }
    }
    #endif

    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        managedObjectContext: NSManagedObjectContext,
        timestampUpdatePublisher: AnyPublisher<Date, Never>,
        statusTableViewCellDelegate: StatusTableViewCellDelegate,
        timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?,
        threadReplyLoaderTableViewCellDelegate: ThreadReplyLoaderTableViewCellDelegate?
    ) -> UITableViewDiffableDataSource<StatusSection, Item> {
        UITableViewDiffableDataSource(tableView: tableView) { [
            weak dependency,
            weak statusTableViewCellDelegate,
            weak timelineMiddleLoaderTableViewCellDelegate,
            weak threadReplyLoaderTableViewCellDelegate
        ] tableView, indexPath, item -> UITableViewCell? in
            guard let dependency = dependency else { return UITableViewCell() }
            guard let statusTableViewCellDelegate = statusTableViewCellDelegate else { return UITableViewCell() }

            switch item {
            case .homeTimelineIndex(objectID: let objectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                let timelineIndex = managedObjectContext.object(with: objectID) as? HomeTimelineIndex

                // note: force check optional for status
                // status maybe <uninitialized> here when delete in thread scene
                guard let status = timelineIndex?.status,
                      let userID = timelineIndex?.userID else {
                    return cell
                }

                // configure cell
                configureStatusTableViewCell(
                    cell: cell,
                    dependency: dependency,
                    readableLayoutFrame: tableView.readableContentGuide.layoutFrame,
                    status: status,
                    requestUserID: userID,
                    statusItemAttribute: attribute
                )
                cell.delegate = statusTableViewCellDelegate
                cell.isAccessibilityElement = true
                return cell
            case .status(let objectID, let attribute),
                 .root(let objectID, let attribute),
                 .reply(let objectID, let attribute),
                 .leaf(let objectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                let activeMastodonAuthenticationBox = dependency.context.authenticationService.activeMastodonAuthenticationBox.value
                let requestUserID = activeMastodonAuthenticationBox?.userID ?? ""
                // configure cell
                managedObjectContext.performAndWait {
                    let status = managedObjectContext.object(with: objectID) as! Status
                    StatusSection.configure(
                        cell: cell,
                        dependency: dependency,
                        readableLayoutFrame: tableView.readableContentGuide.layoutFrame,
                        status: status,
                        requestUserID: requestUserID,
                        statusItemAttribute: attribute
                    )
                    
                    switch item {
                    case .root:
                        StatusSection.configureThreadMeta(cell: cell, status: status)
                        ManagedObjectObserver.observe(object: status.reblog ?? status)
                            .receive(on: RunLoop.main)
                            .sink { _ in
                                // do nothing
                            } receiveValue: { change in
                                guard case .update(let object) = change.changeType,
                                      let status = object as? Status else { return }
                                StatusSection.configureThreadMeta(cell: cell, status: status)
                            }
                            .store(in: &cell.disposeBag)
                    default:
                        break
                    }
                }
                cell.delegate = statusTableViewCellDelegate
                switch item {
                case .root:
                    cell.statusView.activeTextLabel.isAccessibilityElement = false
                    var accessibilityElements: [Any] = []
                    accessibilityElements.append(cell.statusView.avatarView)
                    accessibilityElements.append(cell.statusView.nameLabel)
                    accessibilityElements.append(cell.statusView.dateLabel)
                    accessibilityElements.append(contentsOf: cell.statusView.activeTextLabel.createAccessibilityElements())
                    accessibilityElements.append(contentsOf: cell.statusView.statusMosaicImageViewContainer.imageViews)
                    accessibilityElements.append(cell.statusView.playerContainerView)
                    accessibilityElements.append(cell.statusView.actionToolbarContainer)
                    accessibilityElements.append(cell.threadMetaView)
                    cell.accessibilityElements = accessibilityElements
                default:
                    cell.isAccessibilityElement = true
                    cell.accessibilityElements = nil
                }
                return cell
            case .leafBottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ThreadReplyLoaderTableViewCell.self), for: indexPath) as! ThreadReplyLoaderTableViewCell
                cell.delegate = threadReplyLoaderTableViewCellDelegate
                return cell
            case .publicMiddleLoader(let upperTimelineStatusID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                cell.delegate = timelineMiddleLoaderTableViewCellDelegate
                timelineMiddleLoaderTableViewCellDelegate?.configure(cell: cell, upperTimelineStatusID: upperTimelineStatusID, timelineIndexobjectID: nil)
                return cell
            case .homeMiddleLoader(let upperTimelineIndexObjectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                cell.delegate = timelineMiddleLoaderTableViewCellDelegate
                timelineMiddleLoaderTableViewCellDelegate?.configure(cell: cell, upperTimelineStatusID: nil, timelineIndexobjectID: upperTimelineIndexObjectID)
                return cell
            case .topLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.startAnimating()
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.startAnimating()
                return cell
            case .emptyStateHeader(let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineHeaderTableViewCell.self), for: indexPath) as! TimelineHeaderTableViewCell
                StatusSection.configureEmptyStateHeader(cell: cell, attribute: attribute)
                return cell
            case .reportStatus:
                return UITableViewCell()
            }
        }
    }
}

extension StatusSection {

    static func configureStatusTableViewCell(
        cell: StatusTableViewCell,
        dependency: NeedsDependency,
        readableLayoutFrame: CGRect?,
        status: Status,
        requestUserID: String,
        statusItemAttribute: Item.StatusAttribute
    ) {
        configure(
            cell: cell,
            dependency: dependency,
            readableLayoutFrame: readableLayoutFrame,
            status: status,
            requestUserID: requestUserID,
            statusItemAttribute: statusItemAttribute
        )
    }
    
    static func configure(
        cell: StatusCell,
        dependency: NeedsDependency,
        readableLayoutFrame: CGRect?,
        status: Status,
        requestUserID: String,
        statusItemAttribute: Item.StatusAttribute
    ) {
        // safely cancel the listener when deleted
        ManagedObjectObserver.observe(object: status.reblog ?? status)
            .receive(on: RunLoop.main)
            .sink { _ in
                // do nothing
            } receiveValue: { [weak cell] change in
                guard let cell = cell else { return }
                guard let changeType = change.changeType else { return }
                if case .delete = changeType {
                    cell.disposeBag.removeAll()
                }
            }
            .store(in: &cell.disposeBag)
        
        // set header
        StatusSection.configureStatusViewHeader(cell: cell, status: status)
        // set author: name + username + avatar
        StatusSection.configureStatusViewAuthor(cell: cell, status: status)
        // set timestamp
        let createdAt = (status.reblog ?? status).createdAt
        cell.statusView.dateLabel.text = createdAt.slowedTimeAgoSinceNow
        AppContext.shared.timestampUpdatePublisher
            .receive(on: RunLoop.main)      // will be paused when scrolling (on purpose)
            .sink { [weak cell] _ in
                guard let cell = cell else { return }
                cell.statusView.dateLabel.text = createdAt.slowedTimeAgoSinceNow
                cell.statusView.dateLabel.accessibilityLabel = createdAt.slowedTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)
        // set content
        StatusSection.configureStatusContent(
            cell: cell,
            status: status,
            readableLayoutFrame: readableLayoutFrame,
            statusItemAttribute: statusItemAttribute
        )
        // set content warning
        StatusSection.configureContentWarningOverlay(
            statusView: cell.statusView,
            status: status,
            attribute: statusItemAttribute,
            documentStore: dependency.context.documentStore,
            animated: false
        )
        // set poll
        StatusSection.configurePoll(
            cell: cell,
            poll: (status.reblog ?? status).poll,
            requestUserID: requestUserID,
            updateProgressAnimated: false
        )
        if let poll = (status.reblog ?? status).poll {
            ManagedObjectObserver.observe(object: poll)
                .sink { _ in
                    // do nothing
                } receiveValue: { [weak cell] change in
                    guard let cell = cell else { return }
                    guard case .update(let object) = change.changeType,
                          let newPoll = object as? Poll else { return }
                    StatusSection.configurePoll(
                        cell: cell,
                        poll: newPoll,
                        requestUserID: requestUserID,
                        updateProgressAnimated: true
                    )
                }
                .store(in: &cell.disposeBag)
        }
        // set action toolbar
        if let cell = cell as? StatusTableViewCell {
            StatusSection.configureActionToolBar(
                cell: cell,
                dependency: dependency,
                status: status,
                requestUserID: requestUserID
            )

            // separator line
            cell.separatorLine.isHidden = statusItemAttribute.isSeparatorLineHidden
        }

        // listen model changed
        ManagedObjectObserver.observe(object: status)
            .receive(on: RunLoop.main)
            .sink { _ in
                // do nothing
            } receiveValue: { [weak cell] change in
                guard let cell = cell else { return }
                guard case .update(let object) = change.changeType,
                      let status = object as? Status, !status.isDeleted else {
                    return
                }
                // update header
                StatusSection.configureStatusViewHeader(cell: cell, status: status)
            }
            .store(in: &cell.disposeBag)
        ManagedObjectObserver.observe(object: status.reblog ?? status)
            .receive(on: RunLoop.main)
            .sink { _ in
                // do nothing
            } receiveValue: { [weak cell] change in
                guard let cell = cell else { return }
                guard case .update(let object) = change.changeType,
                      let status = object as? Status, !status.isDeleted else {
                    return
                }
                // update content warning overlay
                StatusSection.configureContentWarningOverlay(
                    statusView: cell.statusView,
                    status: status,
                    attribute: statusItemAttribute,
                    documentStore: dependency.context.documentStore,
                    animated: true
                )
                // update action toolbar
                if let cell = cell as? StatusTableViewCell {
                    StatusSection.configureActionToolBar(
                        cell: cell,
                        dependency: dependency,
                        status: status,
                        requestUserID: requestUserID
                    )
                }
            }
            .store(in: &cell.disposeBag)
    }
    
    static func configureContentWarningOverlay(
        statusView: StatusView,
        status: Status,
        attribute: Item.StatusAttribute,
        documentStore: DocumentStore,
        animated: Bool
    ) {
        statusView.contentWarningOverlayView.blurContentWarningTitleLabel.text = {
            let spoilerText = (status.reblog ?? status).spoilerText ?? ""
            if spoilerText.isEmpty {
                return L10n.Common.Controls.Status.contentWarning
            } else {
                return spoilerText
            }
        }()
        let appStartUpTimestamp = documentStore.appStartUpTimestamp
        
        switch (status.reblog ?? status).sensitiveType {
        case .none:
            statusView.revealContentWarningButton.isHidden = true
            statusView.contentWarningOverlayView.isHidden = true
            statusView.statusMosaicImageViewContainer.contentWarningOverlayView.isHidden = true
            statusView.updateContentWarningDisplay(isHidden: true, animated: false)
        case .all:
            statusView.revealContentWarningButton.isHidden = false
            statusView.contentWarningOverlayView.isHidden = false
            statusView.statusMosaicImageViewContainer.contentWarningOverlayView.isHidden = true
            statusView.playerContainerView.contentWarningOverlayView.isHidden = true
            
            if let revealedAt = status.revealedAt, revealedAt > appStartUpTimestamp {
                statusView.updateRevealContentWarningButton(isRevealing: true)
                statusView.updateContentWarningDisplay(isHidden: true, animated: animated)
                attribute.isRevealing.value = true
            } else {
                statusView.updateRevealContentWarningButton(isRevealing: false)
                statusView.updateContentWarningDisplay(isHidden: false, animated: animated)
                attribute.isRevealing.value = false
            }
        case .media(let isSensitive):
            if !isSensitive, documentStore.defaultRevealStatusDict[status.id] == nil {
                documentStore.defaultRevealStatusDict[status.id] = true
            }
            statusView.revealContentWarningButton.isHidden = false
            statusView.contentWarningOverlayView.isHidden = true
            statusView.statusMosaicImageViewContainer.contentWarningOverlayView.isHidden = false
            statusView.playerContainerView.contentWarningOverlayView.isHidden = false
            statusView.updateContentWarningDisplay(isHidden: true, animated: false)
            
            func updateContentOverlay() {
                let needsReveal: Bool = {
                    if documentStore.defaultRevealStatusDict[status.id] == true {
                        return true
                    }
                    if let revealedAt = status.revealedAt, revealedAt > appStartUpTimestamp {
                        return true
                    }
                    
                    return false
                }()
                attribute.isRevealing.value = needsReveal
                if needsReveal {
                    statusView.updateRevealContentWarningButton(isRevealing: true)
                    statusView.statusMosaicImageViewContainer.contentWarningOverlayView.update(isRevealing: true, style: .media)
                    statusView.playerContainerView.contentWarningOverlayView.update(isRevealing: true, style: .media)
                } else {
                    statusView.updateRevealContentWarningButton(isRevealing: false)
                    statusView.statusMosaicImageViewContainer.contentWarningOverlayView.update(isRevealing: false, style: .media)
                    statusView.playerContainerView.contentWarningOverlayView.update(isRevealing: false, style: .media)
                }
            }
            if animated {
                UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
                    updateContentOverlay()
                } completion: { _ in
                    // do nothing
                }
            } else {
                updateContentOverlay()
            }
        }
    }
    
    static func configureThreadMeta(
        cell: StatusTableViewCell,
        status: Status
    ) {
        cell.selectionStyle = .none
        cell.threadMetaView.dateLabel.text = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: status.createdAt)
        }()
        cell.threadMetaView.dateLabel.accessibilityLabel = DateFormatter.localizedString(from: status.createdAt, dateStyle: .medium, timeStyle: .short)
        let reblogCountTitle: String = {
            let count = status.reblogsCount.intValue
            if count > 1 {
                return L10n.Scene.Thread.Reblog.multiple(String(count))
            } else {
                return L10n.Scene.Thread.Reblog.single(String(count))
            }
        }()
        cell.threadMetaView.reblogButton.setTitle(reblogCountTitle, for: .normal)
        
        let favoriteCountTitle: String = {
            let count = status.favouritesCount.intValue
            if count > 1 {
                return L10n.Scene.Thread.Favorite.multiple(String(count))
            } else {
                return L10n.Scene.Thread.Favorite.single(String(count))
            }
        }()
        cell.threadMetaView.favoriteButton.setTitle(favoriteCountTitle, for: .normal)
        
        cell.threadMetaView.isHidden = false
    }

    static func configureStatusViewHeader(
        cell: StatusCell,
        status: Status
    ) {
        if status.reblog != nil {
            cell.statusView.headerContainerView.isHidden = false
            cell.statusView.headerIconLabel.attributedText = StatusView.iconAttributedString(image: StatusView.reblogIconImage)
            let headerText: String = {
                let author = status.author
                let name = author.displayName.isEmpty ? author.username : author.displayName
                return L10n.Common.Controls.Status.userReblogged(name)
            }()
            MastodonStatusContent.parseResult(content: headerText, emojiDict: status.author.emojiDict)
                .receive(on: DispatchQueue.main)
                .sink { [weak cell] parseResult in
                    guard let cell = cell else { return }
                    cell.statusView.headerInfoLabel.configure(contentParseResult: parseResult)
                }
                .store(in: &cell.disposeBag)
            cell.statusView.headerInfoLabel.isAccessibilityElement = true
        } else if status.inReplyToID != nil {
            cell.statusView.headerContainerView.isHidden = false
            cell.statusView.headerIconLabel.attributedText = StatusView.iconAttributedString(image: StatusView.replyIconImage)
            let headerText: String = {
                guard let replyTo = status.replyTo else {
                    return L10n.Common.Controls.Status.userRepliedTo("-")
                }
                let author = replyTo.author
                let name = author.displayName.isEmpty ? author.username : author.displayName
                return L10n.Common.Controls.Status.userRepliedTo(name)
            }()
            MastodonStatusContent.parseResult(content: headerText, emojiDict: status.replyTo?.author.emojiDict ?? [:])
                .receive(on: DispatchQueue.main)
                .sink { [weak cell] parseResult in
                    guard let cell = cell else { return }
                    cell.statusView.headerInfoLabel.configure(contentParseResult: parseResult)
                }
                .store(in: &cell.disposeBag)
            cell.statusView.headerInfoLabel.isAccessibilityElement = true
        } else {
            cell.statusView.headerContainerView.isHidden = true
            cell.statusView.headerInfoLabel.isAccessibilityElement = false
        }
    }

    static func configureStatusViewAuthor(
        cell: StatusCell,
        status: Status
    ) {
        // name
        let author = (status.reblog ?? status).author
        let nameContent = author.displayNameWithFallback
        cell.statusView.nameLabel.configure(content: nameContent, emojiDict: author.emojiDict)
        // username
        cell.statusView.usernameLabel.text = "@" + author.acct
        // avatar
        if let reblog = status.reblog {
            cell.statusView.avatarImageView.isHidden = true
            cell.statusView.avatarStackedContainerButton.isHidden = false
            cell.statusView.avatarStackedContainerButton.topLeadingAvatarStackedImageView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: reblog.author.avatarImageURL()))
            cell.statusView.avatarStackedContainerButton.bottomTrailingAvatarStackedImageView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: status.author.avatarImageURL()))
        } else {
            cell.statusView.avatarImageView.isHidden = false
            cell.statusView.avatarStackedContainerButton.isHidden = true
            cell.statusView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: status.author.avatarImageURL()))
        }
    }

    static func configureStatusContent(
        cell: StatusCell,
        status: Status,
        readableLayoutFrame: CGRect?,
        statusItemAttribute: Item.StatusAttribute
    ) {
        // set content
        cell.statusView.activeTextLabel.configure(
            content: (status.reblog ?? status).content,
            emojiDict: (status.reblog ?? status).emojiDict
        )
        cell.statusView.activeTextLabel.accessibilityLanguage = (status.reblog ?? status).language

        // set visibility
        if let visibility = (status.reblog ?? status).visibility {
            cell.statusView.updateVisibility(visibility: visibility)

            cell.statusView.revealContentWarningButton.publisher(for: \.isHidden)
                .receive(on: DispatchQueue.main)
                .sink { [weak cell] isHidden in
                    cell?.statusView.visibilityImageView.isHidden = !isHidden
                }
                .store(in: &cell.disposeBag)
        } else {
            cell.statusView.visibilityImageView.isHidden = true
        }

        // prepare media attachments
        let mediaAttachments = Array((status.reblog ?? status).mediaAttachments ?? []).sorted { $0.index.compare($1.index) == .orderedAscending }

        // set image
        let mosaicImageViewModel = MosaicImageViewModel(mediaAttachments: mediaAttachments)
        let imageViewMaxSize: CGSize = {
            let maxWidth: CGFloat = {
                // use timelinePostView width as container width
                // that width follows readable width and keep constant width after rotate
                let containerFrame = readableLayoutFrame ?? cell.statusView.frame
                var containerWidth = containerFrame.width
                containerWidth -= 10
                containerWidth -= StatusView.avatarImageSize.width
                return containerWidth
            }()
            let scale: CGFloat = {
                switch mosaicImageViewModel.metas.count {
                case 1: return 1.3
                default: return 0.7
                }
            }()
            return CGSize(width: maxWidth, height: floor(maxWidth * scale))
        }()
        let mosaics: [MosaicImageViewContainer.ConfigurableMosaic] = {
            if mosaicImageViewModel.metas.count == 1 {
                let meta = mosaicImageViewModel.metas[0]
                let mosaic = cell.statusView.statusMosaicImageViewContainer.setupImageView(aspectRatio: meta.size, maxSize: imageViewMaxSize)
                return [mosaic]
            } else {
                let mosaics = cell.statusView.statusMosaicImageViewContainer.setupImageViews(count: mosaicImageViewModel.metas.count, maxSize: imageViewMaxSize)
                return mosaics
            }
        }()
        for (i, mosaic) in mosaics.enumerated() {
            let imageView = mosaic.imageView
            let blurhashOverlayImageView = mosaic.blurhashOverlayImageView
            let meta = mosaicImageViewModel.metas[i]

            // set blurhash image
            meta.blurhashImagePublisher()
                .sink { image in
                    blurhashOverlayImageView.image = image
                }
                .store(in: &cell.disposeBag)

            let isSingleMosaicLayout = mosaics.count == 1

            // set image
            let imageSize = CGSize(
                width: mosaic.imageViewSize.width * imageView.traitCollection.displayScale,
                height: mosaic.imageViewSize.height * imageView.traitCollection.displayScale
            )
            let request = ImageRequest(
                url: meta.url,
                processors: [
                    ImageProcessors.Resize(
                        size: imageSize,
                        unit: .pixels,
                        contentMode: isSingleMosaicLayout ? .aspectFill : .aspectFit,
                        crop: isSingleMosaicLayout
                    )
                ]
            )
            let options = ImageLoadingOptions(
                transition: .fadeIn(duration: 0.2)
            )

            Nuke.loadImage(
                with: request,
                options: options,
                into: imageView
            ) { result in
                switch result {
                case .failure:
                    break
                case .success:
                    statusItemAttribute.isImageLoaded.value = true
                }
            }

            imageView.accessibilityLabel = meta.altText

            // setup media content overlay trigger
            Publishers.CombineLatest(
                statusItemAttribute.isImageLoaded,
                statusItemAttribute.isRevealing
            )
            .receive(on: DispatchQueue.main)    // needs call immediately
            .sink { [weak cell] isImageLoaded, isMediaRevealing in
                guard let _ = cell else { return }
                guard isImageLoaded else {
                    // always display blurhash image when before image loaded
                    blurhashOverlayImageView.alpha = 1
                    blurhashOverlayImageView.isHidden = false
                    return
                }

                // display blurhash image depends on revealing state
                let animator = UIViewPropertyAnimator(duration: 0.33, curve: .easeInOut)
                animator.addAnimations {
                    blurhashOverlayImageView.alpha = isMediaRevealing ? 0 : 1
                }
                animator.startAnimation()
            }
            .store(in: &cell.disposeBag)
        }
        cell.statusView.statusMosaicImageViewContainer.isHidden = mosaicImageViewModel.metas.isEmpty

        // set audio
        if let audioAttachment = mediaAttachments.filter({ $0.type == .audio }).first {
            cell.statusView.audioView.isHidden = false
            AudioContainerViewModel.configure(cell: cell, audioAttachment: audioAttachment, audioService: AppContext.shared.audioPlaybackService)
        } else {
            cell.statusView.audioView.isHidden = true
        }

        // set GIF & video
        let playerViewMaxSize: CGSize = {
            let maxWidth: CGFloat = {
                // use statusView width as container width
                // that width follows readable width and keep constant width after rotate
                let containerFrame = readableLayoutFrame ?? cell.statusView.frame
                return containerFrame.width
            }()
            let scale: CGFloat = 1.3
            return CGSize(width: maxWidth, height: floor(maxWidth * scale))
        }()

        if let videoAttachment = mediaAttachments.filter({ $0.type == .gifv || $0.type == .video }).first,
           let videoPlayerViewModel = AppContext.shared.videoPlaybackService.dequeueVideoPlayerViewModel(for: videoAttachment) {
            var parent: UIViewController?
            var playerViewControllerDelegate: AVPlayerViewControllerDelegate? = nil
            switch cell {
            case is StatusTableViewCell:
                let statusTableViewCell = cell as! StatusTableViewCell
                parent = statusTableViewCell.delegate?.parent()
                playerViewControllerDelegate = statusTableViewCell.delegate?.playerViewControllerDelegate
            case is NotificationStatusTableViewCell:
                let notificationTableViewCell = cell as! NotificationStatusTableViewCell
                parent = notificationTableViewCell.delegate?.parent()
            case is ReportedStatusTableViewCell:
                let reportTableViewCell = cell as! ReportedStatusTableViewCell
                parent = reportTableViewCell.dependency
            default:
                parent = nil
                assertionFailure("unknown cell")
            }
            let playerContainerView = cell.statusView.playerContainerView
            let playerViewController = playerContainerView.setupPlayer(
                aspectRatio: videoPlayerViewModel.videoSize,
                maxSize: playerViewMaxSize,
                parent: parent
            )
            playerViewController.delegate = playerViewControllerDelegate
            playerViewController.player = videoPlayerViewModel.player
            playerViewController.showsPlaybackControls = videoPlayerViewModel.videoKind != .gif
            playerContainerView.setMediaKind(kind: videoPlayerViewModel.videoKind)
            switch videoPlayerViewModel.videoKind {
            case .gif:
                playerContainerView.setMediaIndicator(isHidden: false)
            case .video:
                playerContainerView.setMediaIndicator(isHidden: true)
            }
            playerContainerView.isHidden = false

            // set blurhash overlay
            playerContainerView.isReadyForDisplay
                .receive(on: DispatchQueue.main)
                .sink { [weak playerContainerView] isReadyForDisplay in
                    guard let playerContainerView = playerContainerView else { return }
                    playerContainerView.blurhashOverlayImageView.alpha = isReadyForDisplay ? 0 : 1
                }
                .store(in: &cell.disposeBag)

            if let blurhash = videoAttachment.blurhash,
               let url = URL(string: videoAttachment.url) {
                AppContext.shared.blurhashImageCacheService.image(
                    blurhash: blurhash,
                    size: playerContainerView.playerViewController.view.frame.size,
                    url: url
                )
                .sink { image in
                    playerContainerView.blurhashOverlayImageView.image = image
                }
                .store(in: &cell.disposeBag)
            }

        } else {
            cell.statusView.playerContainerView.playerViewController.player?.pause()
            cell.statusView.playerContainerView.playerViewController.player = nil
        }
    }
    
    static func configurePoll(
        cell: StatusCell,
        poll: Poll?,
        requestUserID: String,
        updateProgressAnimated: Bool
    ) {
        guard let poll = poll,
              let managedObjectContext = poll.managedObjectContext
        else {
            cell.statusView.pollTableView.isHidden = true
            cell.statusView.pollStatusStackView.isHidden = true
            cell.statusView.pollVoteButton.isHidden = true
            return
        }
        
        cell.statusView.pollTableView.isHidden = false
        cell.statusView.pollStatusStackView.isHidden = false
        cell.statusView.pollVoteCountLabel.text = {
            if poll.multiple {
                let count = poll.votersCount?.intValue ?? 0
                if count > 1 {
                    return L10n.Common.Controls.Status.Poll.VoterCount.single(count)
                } else {
                    return L10n.Common.Controls.Status.Poll.VoterCount.multiple(count)
                }
            } else {
                let count = poll.votesCount.intValue
                if count > 1 {
                    return L10n.Common.Controls.Status.Poll.VoteCount.single(count)
                } else {
                    return L10n.Common.Controls.Status.Poll.VoteCount.multiple(count)
                }
            }
        }()
        if poll.expired {
            cell.statusView.pollCountdownSubscription = nil
            cell.statusView.pollCountdownLabel.text = L10n.Common.Controls.Status.Poll.closed
        } else if let expiresAt = poll.expiresAt {
            cell.statusView.pollCountdownLabel.text = L10n.Common.Controls.Status.Poll.timeLeft(expiresAt.shortTimeAgoSinceNow)
            cell.statusView.pollCountdownSubscription = AppContext.shared.timestampUpdatePublisher
                .sink { _ in
                    cell.statusView.pollCountdownLabel.text = L10n.Common.Controls.Status.Poll.timeLeft(expiresAt.shortTimeAgoSinceNow)
                }
        } else {
            cell.statusView.pollCountdownSubscription = nil
            cell.statusView.pollCountdownLabel.text = "-"
        }
        
        cell.statusView.pollTableView.allowsSelection = !poll.expired
        
        let votedOptions = poll.options.filter { option in
            (option.votedBy ?? Set()).map(\.id).contains(requestUserID)
        }
        let didVotedLocal = !votedOptions.isEmpty
        let didVotedRemote = (poll.votedBy ?? Set()).map(\.id).contains(requestUserID)
        cell.statusView.pollVoteButton.isEnabled = didVotedLocal
        cell.statusView.pollVoteButton.isHidden = !poll.multiple ? true : (didVotedRemote || poll.expired)
        
        cell.statusView.pollTableViewDataSource = PollSection.tableViewDiffableDataSource(
            for: cell.statusView.pollTableView,
            managedObjectContext: managedObjectContext
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<PollSection, PollItem>()
        snapshot.appendSections([.main])

        let pollItems = poll.options
            .sorted(by: { $0.index.intValue < $1.index.intValue })
            .map { option -> PollItem in
                let attribute: PollItem.Attribute = {
                    let selectState: PollItem.Attribute.SelectState = {
                        // check didVotedRemote later to make the local change possible
                        if !votedOptions.isEmpty {
                            return votedOptions.contains(option) ? .on : .off
                        } else if poll.expired {
                            return .none
                        } else if didVotedRemote, votedOptions.isEmpty {
                            return .none
                        } else {
                            return .off
                        }
                    }()
                    let voteState: PollItem.Attribute.VoteState = {
                        var needsReveal: Bool
                        if poll.expired {
                            needsReveal = true
                        } else if didVotedRemote {
                            needsReveal = true
                        } else {
                            needsReveal = false
                        }
                        guard needsReveal else { return .hidden }
                        let percentage: Double = {
                            guard poll.votesCount.intValue > 0 else { return 0.0 }
                            return Double(option.votesCount?.intValue ?? 0) / Double(poll.votesCount.intValue)
                        }()
                        let voted = votedOptions.isEmpty ? true : votedOptions.contains(option)
                        return .reveal(voted: voted, percentage: percentage, animated: updateProgressAnimated)
                    }()
                    return PollItem.Attribute(selectState: selectState, voteState: voteState)
                }()
                let option = PollItem.opion(objectID: option.objectID, attribute: attribute)
                return option
            }
        snapshot.appendItems(pollItems, toSection: .main)
        cell.statusView.pollTableViewDataSource?.apply(snapshot, animatingDifferences: false, completion: nil)
    }

    static func configureActionToolBar(
        cell: StatusTableViewCell,
        dependency: NeedsDependency,
        status: Status,
        requestUserID: String
    ) {
        let status = status.reblog ?? status

        // set reply
        let replyCountTitle: String = {
            let count = status.repliesCount?.intValue ?? 0
            return StatusSection.formattedNumberTitleForActionButton(count)
        }()
        cell.statusView.actionToolbarContainer.replyButton.setTitle(replyCountTitle, for: .normal)
        cell.statusView.actionToolbarContainer.replyButton.accessibilityValue = status.repliesCount.flatMap {
            L10n.Common.Controls.Timeline.Accessibility.countReplies($0.intValue)
        } ?? nil
        // set reblog
        let isReblogged = status.rebloggedBy.flatMap { $0.contains(where: { $0.id == requestUserID }) } ?? false
        let reblogCountTitle: String = {
            let count = status.reblogsCount.intValue
            return StatusSection.formattedNumberTitleForActionButton(count)
        }()
        cell.statusView.actionToolbarContainer.reblogButton.setTitle(reblogCountTitle, for: .normal)
        cell.statusView.actionToolbarContainer.isReblogButtonHighlight = isReblogged
        cell.statusView.actionToolbarContainer.reblogButton.accessibilityLabel = isReblogged ? L10n.Common.Controls.Status.Actions.unreblog : L10n.Common.Controls.Status.Actions.reblog
        cell.statusView.actionToolbarContainer.reblogButton.accessibilityValue = {
            guard status.reblogsCount.intValue > 0 else { return nil }
            return L10n.Common.Controls.Timeline.Accessibility.countReblogs(status.reblogsCount.intValue)
        }()
        // set like
        let isLike = status.favouritedBy.flatMap { $0.contains(where: { $0.id == requestUserID }) } ?? false
        let favoriteCountTitle: String = {
            let count = status.favouritesCount.intValue
            return StatusSection.formattedNumberTitleForActionButton(count)
        }()
        cell.statusView.actionToolbarContainer.favoriteButton.setTitle(favoriteCountTitle, for: .normal)
        cell.statusView.actionToolbarContainer.isFavoriteButtonHighlight = isLike
        cell.statusView.actionToolbarContainer.favoriteButton.accessibilityLabel = isLike ? L10n.Common.Controls.Status.Actions.unfavorite : L10n.Common.Controls.Status.Actions.favorite
        cell.statusView.actionToolbarContainer.favoriteButton.accessibilityValue = {
            guard status.favouritesCount.intValue > 0 else { return nil }
            return L10n.Common.Controls.Timeline.Accessibility.countReblogs(status.favouritesCount.intValue)
        }()
        Publishers.CombineLatest(
            dependency.context.blockDomainService.blockedDomains.setFailureType(to: ManagedObjectObserver.Error.self),
            ManagedObjectObserver.observe(object: status.authorForUserProvider)
        )
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { _ in
            // do nothing
        }, receiveValue: { [weak dependency, weak cell] _, change in
            guard let cell = cell else { return }
            guard let dependency = dependency else { return }
            switch change.changeType {
            case .delete:
                return
            case .update(_):
                break
            case .none:
                break
            }
            StatusSection.setupStatusMoreButtonMenu(cell: cell, dependency: dependency, status: status)
        })
        .store(in: &cell.disposeBag)
        self.setupStatusMoreButtonMenu(cell: cell, dependency: dependency, status: status)
    }

}


extension StatusSection {
    static func configureEmptyStateHeader(
        cell: TimelineHeaderTableViewCell,
        attribute: Item.EmptyStateHeaderAttribute
    ) {
        cell.timelineHeaderView.iconImageView.image = attribute.reason.iconImage
        cell.timelineHeaderView.messageLabel.text = attribute.reason.message
    }
}

extension StatusSection {
    private static func formattedNumberTitleForActionButton(_ number: Int?) -> String {
        guard let number = number, number > 0 else { return "" }
        return String(number)
    }
    
    private static func setupStatusMoreButtonMenu(
        cell: StatusTableViewCell,
        dependency: NeedsDependency,
        status: Status) {
        
        guard let userProvider = dependency as? UserProvider else { fatalError() }
        
        guard let authenticationBox = dependency.context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        let author = status.authorForUserProvider
        let isMyself = authenticationBox.userID == author.id
        let isInSameDomain = authenticationBox.domain == author.domainFromAcct
        let isMuting = (author.mutingBy ?? Set()).map(\.id).contains(authenticationBox.userID)
        let isBlocking = (author.blockingBy ?? Set()).map(\.id).contains(authenticationBox.userID)
        let isDomainBlocking = dependency.context.blockDomainService.blockedDomains.value.contains(author.domainFromAcct)
        cell.statusView.actionToolbarContainer.moreButton.showsMenuAsPrimaryAction = true
        cell.statusView.actionToolbarContainer.moreButton.menu = UserProviderFacade.createProfileActionMenu(
            for: author,
            isMyself: isMyself,
            isMuting: isMuting,
            isBlocking: isBlocking,
            isInSameDomain: isInSameDomain,
            isDomainBlocking: isDomainBlocking,
            provider: userProvider,
            cell: cell,
            sourceView: cell.statusView.actionToolbarContainer.moreButton,
            barButtonItem: nil,
            shareUser: nil,
            shareStatus: status
        )
    }
}
