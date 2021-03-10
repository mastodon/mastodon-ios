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
        timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
    ) -> UITableViewDiffableDataSource<StatusSection, Item> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak statusTableViewCellDelegate, weak timelineMiddleLoaderTableViewCellDelegate] tableView, indexPath, item -> UITableViewCell? in
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
                        toot: timelineIndex.toot,
                        requestUserID: timelineIndex.userID,
                        statusItemAttribute: attribute
                    )
                }
                cell.delegate = statusTableViewCellDelegate
                return cell
            case .toot(let objectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                let activeMastodonAuthenticationBox = dependency.context.authenticationService.activeMastodonAuthenticationBox.value
                let requestUserID = activeMastodonAuthenticationBox?.userID ?? ""
                // configure cell
                managedObjectContext.performAndWait {
                    let toot = managedObjectContext.object(with: objectID) as! Toot
                    StatusSection.configure(
                        cell: cell,
                        dependency: dependency,
                        readableLayoutFrame: tableView.readableContentGuide.layoutFrame,
                        timestampUpdatePublisher: timestampUpdatePublisher,
                        toot: toot,
                        requestUserID: requestUserID,
                        statusItemAttribute: attribute
                    )
                }
                cell.delegate = statusTableViewCellDelegate
                return cell
            case .publicMiddleLoader(let upperTimelineTootID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                cell.delegate = timelineMiddleLoaderTableViewCellDelegate
                timelineMiddleLoaderTableViewCellDelegate?.configure(cell: cell, upperTimelineTootID: upperTimelineTootID, timelineIndexobjectID: nil)
                return cell
            case .homeMiddleLoader(let upperTimelineIndexObjectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                cell.delegate = timelineMiddleLoaderTableViewCellDelegate
                timelineMiddleLoaderTableViewCellDelegate?.configure(cell: cell, upperTimelineTootID: nil, timelineIndexobjectID: upperTimelineIndexObjectID)
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
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
        toot: Toot,
        requestUserID: String,
        statusItemAttribute: Item.StatusAttribute
    ) {
        // set header
        cell.statusView.headerContainerStackView.isHidden = toot.reblog == nil
        cell.statusView.headerInfoLabel.text = {
            let author = toot.author
            let name = author.displayName.isEmpty ? author.username : author.displayName
            return L10n.Common.Controls.Status.userBoosted(name)
        }()
        
        // set name username avatar
        cell.statusView.nameLabel.text = {
            let author = (toot.reblog ?? toot).author
            return author.displayName.isEmpty ? author.username : author.displayName
        }()
        cell.statusView.usernameLabel.text = "@" + (toot.reblog ?? toot).author.acct
        cell.statusView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: (toot.reblog ?? toot).author.avatarImageURL()))
        
        // set text
        cell.statusView.activeTextLabel.config(content: (toot.reblog ?? toot).content)
        
        // set status text content warning
        let spoilerText = (toot.reblog ?? toot).spoilerText ?? ""
        let isStatusTextSensitive = statusItemAttribute.isStatusTextSensitive
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
        let mediaAttachments = Array((toot.reblog ?? toot).mediaAttachments ?? []).sorted { $0.index.compare($1.index) == .orderedAscending }
        
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
        let isStatusSensitive = statusItemAttribute.isStatusSensitive
        cell.statusView.statusMosaicImageViewContainer.blurVisualEffectView.effect = isStatusSensitive ? MosaicImageViewContainer.blurVisualEffect : nil
        cell.statusView.statusMosaicImageViewContainer.vibrancyVisualEffectView.alpha = isStatusSensitive ? 1.0 : 0.0
        
        // set audio
        if let audioAttachment = mediaAttachments.filter({ $0.type == .audio }).first {
            cell.statusView.audioView.isHidden = false
            AudioContainerViewModel.configure(cell: cell, audioAttachment: audioAttachment  )
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
            let mosaicPlayerView = cell.statusView.mosaicPlayerView
            let playerViewController = mosaicPlayerView.setupPlayer(
                aspectRatio: videoPlayerViewModel.videoSize,
                maxSize: playerViewMaxSize,
                parent: parent
            )
            playerViewController.delegate = cell.delegate?.playerViewControllerDelegate
            playerViewController.player = videoPlayerViewModel.player
            playerViewController.showsPlaybackControls = videoPlayerViewModel.videoKind != .gif
            
            mosaicPlayerView.gifIndicatorLabel.isHidden = videoPlayerViewModel.videoKind != .gif
            mosaicPlayerView.isHidden = false
            
        } else {
            cell.statusView.mosaicPlayerView.playerViewController.player?.pause()
            cell.statusView.mosaicPlayerView.playerViewController.player = nil
        }
        // set poll
        let poll = (toot.reblog ?? toot).poll
        StatusSection.configure(
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
                    StatusSection.configure(
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
        let replyCountTitle: String = {
            let count = (toot.reblog ?? toot).repliesCount?.intValue ?? 0
            return StatusSection.formattedNumberTitleForActionButton(count)
        }()
        cell.statusView.actionToolbarContainer.replyButton.setTitle(replyCountTitle, for: .normal)
        
        let isLike = (toot.reblog ?? toot).favouritedBy.flatMap { $0.contains(where: { $0.id == requestUserID }) } ?? false
        let favoriteCountTitle: String = {
            let count = (toot.reblog ?? toot).favouritesCount.intValue
            return StatusSection.formattedNumberTitleForActionButton(count)
        }()
        cell.statusView.actionToolbarContainer.starButton.setTitle(favoriteCountTitle, for: .normal)
        cell.statusView.actionToolbarContainer.isStarButtonHighlight = isLike
        
        // set date
        let createdAt = (toot.reblog ?? toot).createdAt
        cell.statusView.dateLabel.text = createdAt.shortTimeAgoSinceNow
        timestampUpdatePublisher
            .sink { _ in
                cell.statusView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)

        // observe model change
        ManagedObjectObserver.observe(object: toot.reblog ?? toot)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // do nothing
            } receiveValue: { change in
                guard case .update(let object) = change.changeType,
                      let newToot = object as? Toot else { return }
                let targetToot = newToot.reblog ?? newToot

                let isLike = targetToot.favouritedBy.flatMap { $0.contains(where: { $0.id == requestUserID }) } ?? false
                let favoriteCount = targetToot.favouritesCount.intValue
                let favoriteCountTitle = StatusSection.formattedNumberTitleForActionButton(favoriteCount)
                cell.statusView.actionToolbarContainer.starButton.setTitle(favoriteCountTitle, for: .normal)
                cell.statusView.actionToolbarContainer.isStarButtonHighlight = isLike
                os_log("%{public}s[%{public}ld], %{public}s: like count label for toot %s did update: %ld", (#file as NSString).lastPathComponent, #line, #function, targetToot.id, favoriteCount)
            }
            .store(in: &cell.disposeBag)
    }
    
    static func configure(
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
            assertionFailure()
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
}

extension StatusSection {
    private static func formattedNumberTitleForActionButton(_ number: Int?) -> String {
        guard let number = number, number > 0 else { return "" }
        return String(number)
    }
}
