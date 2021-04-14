//
//  NotificationSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import Combine

enum NotificationSection: Equatable, Hashable {
    case main
}

extension NotificationSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        timestampUpdatePublisher: AnyPublisher<Date, Never>,
        managedObjectContext: NSManagedObjectContext,
        delegate: NotificationTableViewCellDelegate,
        dependency: NeedsDependency,
        requestUserID: String
    ) -> UITableViewDiffableDataSource<NotificationSection, NotificationItem> {
        return UITableViewDiffableDataSource(tableView: tableView) {
            [weak delegate,weak dependency]
            (tableView, indexPath, notificationItem) -> UITableViewCell? in
            guard let dependency = dependency else { return nil }
            switch notificationItem {
            case .notification(let objectID):
                
                let notification = managedObjectContext.object(with: objectID) as! MastodonNotification
                let type = Mastodon.Entity.Notification.NotificationType(rawValue: notification.type)
                
                let timeText = notification.createAt.shortTimeAgoSinceNow

                var actionText: String
                var actionImageName: String
                var color: UIColor
                switch type {
                case .follow:
                    actionText = L10n.Scene.Notification.Action.follow
                    actionImageName = "person.crop.circle.badge.checkmark"
                    color = Asset.Colors.brandBlue.color
                case .favourite:
                    actionText = L10n.Scene.Notification.Action.favourite
                    actionImageName = "star.fill"
                    color = Asset.Colors.Notification.favourite.color
                case .reblog:
                    actionText = L10n.Scene.Notification.Action.reblog
                    actionImageName = "arrow.2.squarepath"
                    color = Asset.Colors.Notification.reblog.color
                case .mention:
                    actionText = L10n.Scene.Notification.Action.mention
                    actionImageName = "at"
                    color = Asset.Colors.Notification.mention.color
                case .poll:
                    actionText = L10n.Scene.Notification.Action.poll
                    actionImageName = "list.bullet"
                    color = Asset.Colors.brandBlue.color
                default:
                    actionText = ""
                    actionImageName = ""
                    color = .clear
                }
                
                if let status = notification.status {
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationStatusTableViewCell.self), for: indexPath) as! NotificationStatusTableViewCell
                    cell.delegate = delegate
                    let frame = CGRect(x: 0, y: 0, width: tableView.readableContentGuide.layoutFrame.width - NotificationStatusTableViewCell.statusPadding.left - NotificationStatusTableViewCell.statusPadding.right, height: tableView.readableContentGuide.layoutFrame.height)
                    NotificationSection.configure(cell: cell,
                                                  dependency: dependency,
                                                  readableLayoutFrame: frame,
                                                  timestampUpdatePublisher: timestampUpdatePublisher,
                                                  status: status,
                                                  requestUserID: requestUserID,
                                                  statusItemAttribute: Item.StatusAttribute(isStatusTextSensitive: false, isStatusSensitive: false))
                    timestampUpdatePublisher
                        .sink { _ in
                            let timeText = notification.createAt.shortTimeAgoSinceNow
                            cell.actionLabel.text = actionText + " · " + timeText
                        }
                        .store(in: &cell.disposeBag)
                    cell.actionImageBackground.backgroundColor = color
                    cell.actionLabel.text = actionText + " · " + timeText
                    cell.nameLabel.text = notification.account.displayName.isEmpty ? notification.account.username : notification.account.displayName
                    cell.avatatImageView.af.setImage(
                        withURL: URL(string: notification.account.avatar)!,
                        placeholderImage: UIImage.placeholder(color: .systemFill),
                        imageTransition: .crossDissolve(0.2)
                    )
                    cell.avatatImageView.gesture().sink { [weak cell] _ in
                        cell?.delegate?.userAvatarDidPressed(notification: notification)
                    }
                    .store(in: &cell.disposeBag)
                    if let actionImage = UIImage(systemName: actionImageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))?.withRenderingMode(.alwaysTemplate) {
                        cell.actionImageView.image = actionImage
                    }
                    return cell
                    
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationTableViewCell.self), for: indexPath) as! NotificationTableViewCell
                    cell.delegate = delegate
                    timestampUpdatePublisher
                        .sink { _ in
                            let timeText = notification.createAt.shortTimeAgoSinceNow
                            cell.actionLabel.text = actionText + " · " + timeText
                        }
                        .store(in: &cell.disposeBag)
                    cell.actionImageBackground.backgroundColor = color
                    cell.actionLabel.text = actionText + " · " + timeText
                    cell.nameLabel.text = notification.account.displayName.isEmpty ? notification.account.username : notification.account.displayName
                    cell.avatatImageView.af.setImage(
                        withURL: URL(string: notification.account.avatar)!,
                        placeholderImage: UIImage.placeholder(color: .systemFill),
                        imageTransition: .crossDissolve(0.2)
                    )
                    cell.avatatImageView.gesture().sink { [weak cell] _ in
                        cell?.delegate?.userAvatarDidPressed(notification: notification)
                    }
                    .store(in: &cell.disposeBag)
                    if let actionImage = UIImage(systemName: actionImageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))?.withRenderingMode(.alwaysTemplate) {
                        cell.actionImageView.image = actionImage
                    }
                    return cell
                }
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CommonBottomLoader.self)) as! CommonBottomLoader
                cell.startAnimating()
                return cell
            }
        }
    }
}


extension NotificationSection {
    static func configure(
        cell: NotificationStatusTableViewCell,
        dependency: NeedsDependency,
        readableLayoutFrame: CGRect?,
        timestampUpdatePublisher: AnyPublisher<Date, Never>,
        status: Status,
        requestUserID: String,
        statusItemAttribute: Item.StatusAttribute
    ) {
                
        // setup attribute
        statusItemAttribute.setupForStatus(status: status)
        
        // set header
        NotificationSection.configureHeader(cell: cell, status: status)
        ManagedObjectObserver.observe(object: status)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // do nothing
            } receiveValue: { change in
                guard case .update(let object) = change.changeType,
                      let newStatus = object as? Status else { return }
                NotificationSection.configureHeader(cell: cell, status: newStatus)
            }
            .store(in: &cell.disposeBag)
        
        // set name username
        cell.statusView.nameLabel.text = {
            let author = (status.reblog ?? status).author
            return author.displayName.isEmpty ? author.username : author.displayName
        }()
        cell.statusView.usernameLabel.text = "@" + (status.reblog ?? status).author.acct
        // set avatar

        cell.statusView.avatarButton.isHidden = false
        cell.statusView.avatarStackedContainerButton.isHidden = true
        cell.statusView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: status.author.avatarImageURL()))
        
        
        // set text
        cell.statusView.activeTextLabel.configure(content: (status.reblog ?? status).content)
        
        // set status text content warning
        let isStatusTextSensitive = statusItemAttribute.isStatusTextSensitive ?? false
        let spoilerText = (status.reblog ?? status).spoilerText ?? ""
        cell.statusView.isStatusTextSensitive = isStatusTextSensitive
        cell.statusView.updateContentWarningDisplay(isHidden: !isStatusTextSensitive)
        cell.statusView.contentWarningTitle.text = {
            if spoilerText.isEmpty {
                return L10n.Common.Controls.Status.statusContentWarning
            } else {
                return L10n.Common.Controls.Status.statusContentWarning + ": \(spoilerText)"
            }
        }()
        
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
        if mosiacImageViewModel.metas.count == 1 {
            let meta = mosiacImageViewModel.metas[0]
            let imageView = cell.statusView.statusMosaicImageViewContainer.setupImageView(aspectRatio: meta.size, maxSize: imageViewMaxSize)
            imageView.af.setImage(
                withURL: meta.url,
                placeholderImage: UIImage.placeholder(color: .systemFill),
                imageTransition: .crossDissolve(0.2)
            )
        } else {
            let imageViews = cell.statusView.statusMosaicImageViewContainer.setupImageViews(count: mosiacImageViewModel.metas.count, maxHeight: imageViewMaxSize.height)
            for (i, imageView) in imageViews.enumerated() {
                let meta = mosiacImageViewModel.metas[i]
                imageView.af.setImage(
                    withURL: meta.url,
                    placeholderImage: UIImage.placeholder(color: .systemFill),
                    imageTransition: .crossDissolve(0.2)
                )
            }
        }
        cell.statusView.statusMosaicImageViewContainer.isHidden = mosiacImageViewModel.metas.isEmpty
        let isStatusSensitive = statusItemAttribute.isStatusSensitive ?? false
        cell.statusView.statusMosaicImageViewContainer.contentWarningOverlayView.blurVisualEffectView.effect = isStatusSensitive ? ContentWarningOverlayView.blurVisualEffect : nil
        cell.statusView.statusMosaicImageViewContainer.contentWarningOverlayView.vibrancyVisualEffectView.alpha = isStatusSensitive ? 1.0 : 0.0
        cell.statusView.statusMosaicImageViewContainer.contentWarningOverlayView.isUserInteractionEnabled = isStatusSensitive
        
        // set audio
        if let _ = mediaAttachments.filter({ $0.type == .audio }).first {
            cell.statusView.audioView.isHidden = false
            cell.statusView.audioView.playButton.isSelected = false
            cell.statusView.audioView.slider.isEnabled = false
            cell.statusView.audioView.slider.setValue(0, animated: false)
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
        
        cell.statusView.playerContainerView.contentWarningOverlayView.blurVisualEffectView.effect = isStatusSensitive ? ContentWarningOverlayView.blurVisualEffect : nil
        cell.statusView.playerContainerView.contentWarningOverlayView.vibrancyVisualEffectView.alpha = isStatusSensitive ? 1.0 : 0.0
        cell.statusView.playerContainerView.contentWarningOverlayView.isUserInteractionEnabled = isStatusSensitive
        
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
        // set poll
        let poll = (status.reblog ?? status).poll
        NotificationSection.configurePoll(
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
                    NotificationSection.configurePoll(
                        cell: cell,
                        poll: newPoll,
                        requestUserID: requestUserID,
                        updateProgressAnimated: true,
                        timestampUpdatePublisher: timestampUpdatePublisher
                    )
                }
                .store(in: &cell.disposeBag)
        }
        
        // set date
        let createdAt = (status.reblog ?? status).createdAt
        cell.statusView.dateLabel.text = createdAt.shortTimeAgoSinceNow
        timestampUpdatePublisher
            .sink { _ in
                cell.statusView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)

    }

    static func configureHeader(
        cell: NotificationStatusTableViewCell,
        status: Status
    ) {
        if status.reblog != nil {
            cell.statusView.headerContainerStackView.isHidden = false
            cell.statusView.headerIconLabel.attributedText = StatusView.iconAttributedString(image: StatusView.boostIconImage)
            cell.statusView.headerInfoLabel.text = {
                let author = status.author
                let name = author.displayName.isEmpty ? author.username : author.displayName
                return L10n.Common.Controls.Status.userReblogged(name)
            }()
        } else if let replyTo = status.replyTo {
            cell.statusView.headerContainerStackView.isHidden = false
            cell.statusView.headerIconLabel.attributedText = StatusView.iconAttributedString(image: StatusView.replyIconImage)
            cell.statusView.headerInfoLabel.text = {
                let author = replyTo.author
                let name = author.displayName.isEmpty ? author.username : author.displayName
                return L10n.Common.Controls.Status.userRepliedTo(name)
            }()
        } else {
            cell.statusView.headerContainerStackView.isHidden = true
        }
    }
    
    
    static func configurePoll(
        cell: NotificationStatusTableViewCell,
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

extension NotificationSection  {
    private static func formattedNumberTitleForActionButton(_ number: Int?) -> String {
        guard let number = number, number > 0 else { return "" }
        return String(number)
    }
}
