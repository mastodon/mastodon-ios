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

enum StatusSection: Equatable, Hashable {
    case main
}

extension StatusSection {
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

                // configure cell
                managedObjectContext.performAndWait {
                    let timelineIndex = managedObjectContext.object(with: objectID) as! HomeTimelineIndex
                    StatusSection.configure(
                        cell: cell,
                        dependency: dependency,
                        readableLayoutFrame: tableView.readableContentGuide.layoutFrame,
                        timestampUpdatePublisher: timestampUpdatePublisher,
                        status: timelineIndex.status,
                        requestUserID: timelineIndex.userID,
                        statusItemAttribute: attribute
                    )
                }
                cell.delegate = statusTableViewCellDelegate
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
                        timestampUpdatePublisher: timestampUpdatePublisher,
                        status: status,
                        requestUserID: requestUserID,
                        statusItemAttribute: attribute
                    )
                    
                    switch item {
                    case .root:
                        StatusSection.configureThreadMeta(cell: cell, status: status)
                        ManagedObjectObserver.observe(object: status.reblog ?? status)
                            .receive(on: DispatchQueue.main)
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
            }
        }
    }
}

extension StatusSection {
    
    static func configure(
        cell: StatusTableViewCell,
        dependency: NeedsDependency,
        readableLayoutFrame: CGRect?,
        timestampUpdatePublisher: AnyPublisher<Date, Never>,
        status: Status,
        requestUserID: String,
        statusItemAttribute: Item.StatusAttribute
    ) { 
        // set header
        StatusSection.configureHeader(cell: cell, status: status)
        ManagedObjectObserver.observe(object: status)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // do nothing
            } receiveValue: { change in
                guard case .update(let object) = change.changeType,
                      let newStatus = object as? Status else { return }
                StatusSection.configureHeader(cell: cell, status: newStatus)
            }
            .store(in: &cell.disposeBag)
        
        // set name username
        cell.statusView.nameLabel.text = {
            let author = (status.reblog ?? status).author
            return author.displayName.isEmpty ? author.username : author.displayName
        }()
        cell.statusView.usernameLabel.text = "@" + (status.reblog ?? status).author.acct
        // set avatar
        if let reblog = status.reblog {
            cell.statusView.avatarButton.isHidden = true
            cell.statusView.avatarStackedContainerButton.isHidden = false
            cell.statusView.avatarStackedContainerButton.topLeadingAvatarStackedImageView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: reblog.author.avatarImageURL()))
            cell.statusView.avatarStackedContainerButton.bottomTrailingAvatarStackedImageView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: status.author.avatarImageURL()))
        } else {
            cell.statusView.avatarButton.isHidden = false
            cell.statusView.avatarStackedContainerButton.isHidden = true
            cell.statusView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: status.author.avatarImageURL()))
        }
        
        // set text
        cell.statusView.activeTextLabel.configure(content: (status.reblog ?? status).content)
        
        // prepare media attachments
        let mediaAttachments = Array((status.reblog ?? status).mediaAttachments ?? []).sorted { $0.index.compare($1.index) == .orderedAscending }
        
        // set image
        let mosiacImageViewModel = MosaicImageViewModel(mediaAttachments: mediaAttachments)
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
                switch mosiacImageViewModel.metas.count {
                case 1: return 1.3
                default: return 0.7
                }
            }()
            return CGSize(width: maxWidth, height: maxWidth * scale)
        }()
        let blurhashImageCache = dependency.context.documentStore.blurhashImageCache
        let mosaics: [MosaicImageViewContainer.ConfigurableMosaic] = {
            if mosiacImageViewModel.metas.count == 1 {
                let meta = mosiacImageViewModel.metas[0]
                let mosaic = cell.statusView.statusMosaicImageViewContainer.setupImageView(aspectRatio: meta.size, maxSize: imageViewMaxSize)
                return [mosaic]
            } else {
                let mosaics = cell.statusView.statusMosaicImageViewContainer.setupImageViews(count: mosiacImageViewModel.metas.count, maxHeight: imageViewMaxSize.height)
                return mosaics
            }
        }()
        for (i, mosiac) in mosaics.enumerated() {
            let (imageView, blurhashOverlayImageView) = mosiac
            let meta = mosiacImageViewModel.metas[i]
            let blurhashImageDataKey = meta.url.absoluteString as NSString
            if let blurhashImageData = blurhashImageCache.object(forKey: meta.url.absoluteString as NSString),
               let image = UIImage(data: blurhashImageData as Data) {
                blurhashOverlayImageView.image = image
            } else {
                meta.blurhashImagePublisher()
                    .receive(on: DispatchQueue.main)
                    .sink { image in
                        blurhashOverlayImageView.image = image
                        image?.pngData().flatMap {
                            blurhashImageCache.setObject($0 as NSData, forKey: blurhashImageDataKey)
                        }
                    }
                    .store(in: &cell.disposeBag)
            }
            imageView.af.setImage(
                withURL: meta.url,
                placeholderImage: UIImage.placeholder(color: .systemFill),
                imageTransition: .crossDissolve(0.2)
            ) { response in
                switch response.result {
                case .success:
                    statusItemAttribute.isImageLoaded.value = true
                case .failure:
                    break
                }
            }
            Publishers.CombineLatest(
                statusItemAttribute.isImageLoaded,
                statusItemAttribute.isMediaRevealing
            )
            .receive(on: DispatchQueue.main)
            .sink { isImageLoaded, isMediaRevealing in
                guard isImageLoaded else {
                    blurhashOverlayImageView.alpha = 1
                    blurhashOverlayImageView.isHidden = false
                    return
                }
                
                blurhashOverlayImageView.alpha = isMediaRevealing ? 0 : 1
                if isMediaRevealing {
                    let animator = UIViewPropertyAnimator(duration: 0.33, curve: .easeInOut)
                    animator.addAnimations {
                        blurhashOverlayImageView.alpha = isMediaRevealing ? 0 : 1
                    }
                    animator.startAnimation()
                } else {
                    cell.statusView.drawContentWarningImageView()
                }
            }
            .store(in: &cell.disposeBag)
        }
        cell.statusView.statusMosaicImageViewContainer.isHidden = mosiacImageViewModel.metas.isEmpty
        
        // set audio
        if let audioAttachment = mediaAttachments.filter({ $0.type == .audio }).first {
            cell.statusView.audioView.isHidden = false
            AudioContainerViewModel.configure(cell: cell, audioAttachment: audioAttachment, audioService: dependency.context.audioPlaybackService)
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
            return CGSize(width: maxWidth, height: maxWidth * scale)
        }()
        
        if let videoAttachment = mediaAttachments.filter({ $0.type == .gifv || $0.type == .video }).first,
           let videoPlayerViewModel = dependency.context.videoPlaybackService.dequeueVideoPlayerViewModel(for: videoAttachment)
        {
            let parent = cell.delegate?.parent()
            let playerContainerView = cell.statusView.playerContainerView
            let playerViewController = playerContainerView.setupPlayer(
                aspectRatio: videoPlayerViewModel.videoSize,
                maxSize: playerViewMaxSize,
                parent: parent
            )
            playerViewController.delegate = cell.delegate?.playerViewControllerDelegate
            playerViewController.player = videoPlayerViewModel.player
            playerViewController.showsPlaybackControls = videoPlayerViewModel.videoKind != .gif
            playerContainerView.setMediaKind(kind: videoPlayerViewModel.videoKind)
            if videoPlayerViewModel.videoKind == .gif {
                playerContainerView.setMediaIndicator(isHidden: false)
            } else {
                videoPlayerViewModel.timeControlStatus.sink { timeControlStatus in
                    UIView.animate(withDuration: 0.33) {
                        switch timeControlStatus {
                        case .playing:
                            playerContainerView.setMediaIndicator(isHidden: true)
                        case .paused, .waitingToPlayAtSpecifiedRate:
                            playerContainerView.setMediaIndicator(isHidden: false)
                        @unknown default:
                            assertionFailure()
                        }
                    }
                }
                .store(in: &cell.disposeBag)
            }
            playerContainerView.isHidden = false
            
        } else {
            cell.statusView.playerContainerView.playerViewController.player?.pause()
            cell.statusView.playerContainerView.playerViewController.player = nil
        }
        
        // set text content warning
        StatusSection.configureContentWarningOverlay(
            statusView: cell.statusView,
            status: status,
            attribute: statusItemAttribute,
            documentStore: dependency.context.documentStore,
            animated: false
        )
        // observe model change
        ManagedObjectObserver.observe(object: status)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // do nothing
            } receiveValue: { [weak dependency] change in
                guard let dependency = dependency else { return }
                guard case .update(let object) = change.changeType,
                      let status = object as? Status else { return }
                StatusSection.configureContentWarningOverlay(
                    statusView: cell.statusView,
                    status: status,
                    attribute: statusItemAttribute,
                    documentStore: dependency.context.documentStore,
                    animated: true
                )
            }
            .store(in: &cell.disposeBag)
        
        // set poll
        let poll = (status.reblog ?? status).poll
        StatusSection.configurePoll(
            cell: cell,
            poll: poll,
            requestUserID: requestUserID,
            updateProgressAnimated: false,
            timestampUpdatePublisher: timestampUpdatePublisher
        )
        if let poll = poll {
            ManagedObjectObserver.observe(object: poll)
                .sink { _ in
                    // do nothing
                } receiveValue: { change in
                    guard case .update(let object) = change.changeType,
                          let newPoll = object as? Poll else { return }
                    StatusSection.configurePoll(
                        cell: cell,
                        poll: newPoll,
                        requestUserID: requestUserID,
                        updateProgressAnimated: true,
                        timestampUpdatePublisher: timestampUpdatePublisher
                    )
                }
                .store(in: &cell.disposeBag)
        }
        
        // toolbar
        StatusSection.configureActionToolBar(cell: cell, status: status, requestUserID: requestUserID)
        
        // separator line
        cell.separatorLine.isHidden = statusItemAttribute.isSeparatorLineHidden
        
        // set date
        let createdAt = (status.reblog ?? status).createdAt
        cell.statusView.dateLabel.text = createdAt.shortTimeAgoSinceNow
        timestampUpdatePublisher
            .sink { _ in
                cell.statusView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)

        // observe model change
        ManagedObjectObserver.observe(object: status.reblog ?? status)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // do nothing
            } receiveValue: { change in
                guard case .update(let object) = change.changeType,
                      let status = object as? Status else { return }
                StatusSection.configureActionToolBar(cell: cell, status: status, requestUserID: requestUserID)
                
                os_log("%{public}s[%{public}ld], %{public}s: reblog count label for status %s did update: %ld", (#file as NSString).lastPathComponent, #line, #function, status.id, status.reblogsCount.intValue)
                os_log("%{public}s[%{public}ld], %{public}s: like count label for status %s did update: %ld", (#file as NSString).lastPathComponent, #line, #function, status.id, status.favouritesCount.intValue)
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
                return L10n.Common.Controls.Status.contentWarningText(spoilerText)
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
            
            if let revealedAt = status.revealedAt, revealedAt > appStartUpTimestamp {
                statusView.updateRevealContentWarningButton(isRevealing: true)
                statusView.updateContentWarningDisplay(isHidden: true, animated: animated)
                attribute.isMediaRevealing.value = true
            } else {
                statusView.updateRevealContentWarningButton(isRevealing: false)
                statusView.updateContentWarningDisplay(isHidden: false, animated: animated)
                attribute.isMediaRevealing.value = false
            }
        case .media(let isSensitive):
            if !isSensitive, documentStore.defaultRevealStatusDict[status.id] == nil {
                documentStore.defaultRevealStatusDict[status.id] = true
            }
            statusView.revealContentWarningButton.isHidden = false
            statusView.contentWarningOverlayView.isHidden = true
            statusView.statusMosaicImageViewContainer.contentWarningOverlayView.isHidden = false
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
                attribute.isMediaRevealing.value = needsReveal
                if needsReveal {
                    statusView.updateRevealContentWarningButton(isRevealing: true)
                    statusView.statusMosaicImageViewContainer.contentWarningOverlayView.blurVisualEffectView.effect = nil
                    statusView.statusMosaicImageViewContainer.contentWarningOverlayView.vibrancyVisualEffectView.alpha = 0.0
                    statusView.statusMosaicImageViewContainer.isUserInteractionEnabled = false
                } else {
                    statusView.updateRevealContentWarningButton(isRevealing: false)
                    statusView.statusMosaicImageViewContainer.contentWarningOverlayView.blurVisualEffectView.effect = ContentWarningOverlayView.blurVisualEffect
                    statusView.statusMosaicImageViewContainer.contentWarningOverlayView.vibrancyVisualEffectView.alpha = 1.0
                    statusView.statusMosaicImageViewContainer.isUserInteractionEnabled = true
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
    

    static func configureHeader(
        cell: StatusTableViewCell,
        status: Status
    ) {
        if status.reblog != nil {
            cell.statusView.headerContainerStackView.isHidden = false
            cell.statusView.headerIconLabel.attributedText = StatusView.iconAttributedString(image: StatusView.reblogIconImage)
            cell.statusView.headerInfoLabel.text = {
                let author = status.author
                let name = author.displayName.isEmpty ? author.username : author.displayName
                return L10n.Common.Controls.Status.userReblogged(name)
            }()
        } else if status.inReplyToID != nil {
            cell.statusView.headerContainerStackView.isHidden = false
            cell.statusView.headerIconLabel.attributedText = StatusView.iconAttributedString(image: StatusView.replyIconImage)
            cell.statusView.headerInfoLabel.text = {
                guard let replyTo = status.replyTo else {
                    return L10n.Common.Controls.Status.userRepliedTo("-")
                }
                let author = replyTo.author
                let name = author.displayName.isEmpty ? author.username : author.displayName
                return L10n.Common.Controls.Status.userRepliedTo(name)
            }()
        } else {
            cell.statusView.headerContainerStackView.isHidden = true
        }
    }
    
    static func configureActionToolBar(
        cell: StatusTableViewCell,
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
        // set reblog
        let isReblogged = status.rebloggedBy.flatMap { $0.contains(where: { $0.id == requestUserID }) } ?? false
        let reblogCountTitle: String = {
            let count = status.reblogsCount.intValue
            return StatusSection.formattedNumberTitleForActionButton(count)
        }()
        cell.statusView.actionToolbarContainer.reblogButton.setTitle(reblogCountTitle, for: .normal)
        cell.statusView.actionToolbarContainer.isReblogButtonHighlight = isReblogged
        // set like
        let isLike = status.favouritedBy.flatMap { $0.contains(where: { $0.id == requestUserID }) } ?? false
        let favoriteCountTitle: String = {
            let count = status.favouritesCount.intValue
            return StatusSection.formattedNumberTitleForActionButton(count)
        }()
        cell.statusView.actionToolbarContainer.favoriteButton.setTitle(favoriteCountTitle, for: .normal)
        cell.statusView.actionToolbarContainer.isFavoriteButtonHighlight = isLike
    }
    
    static func configurePoll(
        cell: StatusTableViewCell,
        poll: Poll?,
        requestUserID: String,
        updateProgressAnimated: Bool,
        timestampUpdatePublisher: AnyPublisher<Date, Never>
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
            cell.pollCountdownSubscription = nil
            cell.statusView.pollCountdownLabel.text = L10n.Common.Controls.Status.Poll.closed
        } else if let expiresAt = poll.expiresAt {
            cell.statusView.pollCountdownLabel.text = L10n.Common.Controls.Status.Poll.timeLeft(expiresAt.shortTimeAgoSinceNow)
            cell.pollCountdownSubscription = timestampUpdatePublisher
                .sink { _ in
                    cell.statusView.pollCountdownLabel.text = L10n.Common.Controls.Status.Poll.timeLeft(expiresAt.shortTimeAgoSinceNow)
                }
        } else {
            // assertionFailure()
            cell.pollCountdownSubscription = nil
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
}
