//
//  NotificationSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import MetaTextKit
import MastodonMeta
import MastodonAsset
import MastodonLocalization

enum NotificationSection: Equatable, Hashable {
    case main
}

extension NotificationSection {
    
    struct Configuration {
        weak var notificationTableViewCellDelegate: NotificationTableViewCellDelegate?
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<NotificationSection, NotificationItem> {
        tableView.register(NotificationTableViewCell.self, forCellReuseIdentifier: String(describing: NotificationTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .feed(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationTableViewCell.self), for: indexPath) as! NotificationTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        context: context,
                        tableView: tableView,
                        cell: cell,
                        viewModel: NotificationTableViewCell.ViewModel(value: .feed(feed)),
                        configuration: configuration
                    )
                }
                return cell
            case .feedLoader(let record):
                return UITableViewCell()
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
//            switch notificationItem {
//            case .notification(let objectID, let attribute):
//                guard let notification = try? managedObjectContext.existingObject(with: objectID) as? MastodonNotification,
//                      !notification.isDeleted
//                else { return UITableViewCell() }
//
//                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationStatusTableViewCell.self), for: indexPath) as! NotificationStatusTableViewCell
//                configure(
//                    tableView: tableView,
//                    cell: cell,
//                    notification: notification,
//                    dependency: dependency,
//                    attribute: attribute
//                )
//                cell.delegate = delegate
//                cell.isAccessibilityElement = true
//                NotificationSection.configureStatusAccessibilityLabel(cell: cell)
//                return cell
//
//            case .notificationStatus(objectID: let objectID, attribute: let attribute):
//                guard let notification = try? managedObjectContext.existingObject(with: objectID) as? MastodonNotification,
//                      !notification.isDeleted,
//                      let status = notification.status,
//                      let requestUserID = dependency.context.authenticationService.activeMastodonAuthenticationBox.value?.userID
//                else { return UITableViewCell() }
//                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
//
//                // configure cell
//                StatusSection.configureStatusTableViewCell(
//                    cell: cell,
//                    tableView: tableView,
//                    timelineContext: .notifications,
//                    dependency: dependency,
//                    readableLayoutFrame: tableView.readableContentGuide.layoutFrame,
//                    status: status,
//                    requestUserID: requestUserID,
//                    statusItemAttribute: attribute
//                )
//                cell.statusView.headerContainerView.isHidden = true     // set header hide
//                cell.statusView.actionToolbarContainer.isHidden = true  // set toolbar hide
//                cell.statusView.actionToolbarPlaceholderPaddingView.isHidden = false
//                cell.delegate = statusTableViewCellDelegate
//                cell.isAccessibilityElement = true
//                StatusSection.configureStatusAccessibilityLabel(cell: cell)
//                return cell
//
//            case .bottomLoader:
//                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self)) as! TimelineBottomLoaderTableViewCell
//                cell.startAnimating()
//                return cell
//            }
        }
    }
}

extension NotificationSection {
    
    static func configure(
        context: AppContext,
        tableView: UITableView,
        cell: NotificationTableViewCell,
        viewModel: NotificationTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        StatusSection.setupStatusPollDataSource(
            context: context,
            statusView: cell.notificationView.statusView
        )
        
        StatusSection.setupStatusPollDataSource(
            context: context,
            statusView: cell.notificationView.quoteStatusView
        )
        
        context.authenticationService.activeMastodonAuthenticationBox
            .map { $0 as UserIdentifier? }
            .assign(to: \.userIdentifier, on: cell.notificationView.viewModel)
            .store(in: &cell.disposeBag)
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.notificationTableViewCellDelegate
        )
    }
    
//    static func configure(
//        tableView: UITableView,
//        cell: NotificationStatusTableViewCell,
//        notification: MastodonNotification,
//        dependency: NeedsDependency,
//        attribute: Item.StatusAttribute
//    ) {
//        // configure author
//        cell.configure(
//            with: AvatarConfigurableViewConfiguration(
//                avatarImageURL: notification.account.avatarImageURL()
//            )
//        )
//        
//        func createActionImage() -> UIImage? {
//            return UIImage(
//                systemName: notification.notificationType.actionImageName,
//                withConfiguration: UIImage.SymbolConfiguration(
//                    pointSize: 12, weight: .semibold
//                )
//            )?
//                .withTintColor(.systemBackground)
//                .af.imageAspectScaled(toFit: CGSize(width: 14, height: 14))
//        }
//        
//        cell.avatarButton.badgeImageView.backgroundColor = notification.notificationType.color
//        cell.avatarButton.badgeImageView.image = createActionImage()
//        cell.traitCollectionDidChange
//            .receive(on: DispatchQueue.main)
//            .sink { [weak cell] in
//                guard let cell = cell else { return }
//                cell.avatarButton.badgeImageView.image = createActionImage()
//            }
//            .store(in: &cell.disposeBag)
//        
//        // configure author name, notification description, timestamp
//        let nameText = notification.account.displayNameWithFallback
//        let titleLabelText: String = {
//            switch notification.notificationType {
//            case .favourite:            return L10n.Scene.Notification.userFavoritedYourPost(nameText)
//            case .follow:               return L10n.Scene.Notification.userFollowedYou(nameText)
//            case .followRequest:        return L10n.Scene.Notification.userRequestedToFollowYou(nameText)
//            case .mention:              return L10n.Scene.Notification.userMentionedYou(nameText)
//            case .poll:                 return L10n.Scene.Notification.userYourPollHasEnded(nameText)
//            case .reblog:               return L10n.Scene.Notification.userRebloggedYourPost(nameText)
//            default:                    return ""
//            }
//        }()
//        
//        do {
//            let nameContent = MastodonContent(content: nameText, emojis: notification.account.emojiMeta)
//            let nameMetaContent = try MastodonMetaContent.convert(document: nameContent)
//            
//            let mastodonContent = MastodonContent(content: titleLabelText, emojis: notification.account.emojiMeta)
//            let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
//            
//            cell.titleLabel.configure(content: metaContent)
//            
//            if let nameRange = metaContent.string.range(of: nameMetaContent.string) {
//                let nsRange = NSRange(nameRange, in: metaContent.string)
//                cell.titleLabel.textStorage.addAttributes([
//                    .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold), maximumPointSize: 20),
//                    .foregroundColor: Asset.Colors.brandBlue.color,
//                ], range: nsRange)
//            }
//            
//        } catch {
//            let metaContent = PlaintextMetaContent(string: titleLabelText)
//            cell.titleLabel.configure(content: metaContent)
//        }
//        
//        let createAt = notification.createAt
//        cell.timestampLabel.text = createAt.localizedSlowedTimeAgoSinceNow
//        AppContext.shared.timestampUpdatePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak cell] _ in
//                guard let cell = cell else { return }
//                cell.timestampLabel.text = createAt.localizedSlowedTimeAgoSinceNow
//            }
//            .store(in: &cell.disposeBag)
//        
//        // configure follow request (if exist)
//        if case .followRequest = notification.notificationType {
//            cell.acceptButton.publisher(for: .touchUpInside)
//                .sink { [weak cell] _ in
//                    guard let cell = cell else { return }
//                    cell.delegate?.notificationTableViewCell(cell, notification: notification, acceptButtonDidPressed: cell.acceptButton)
//                }
//                .store(in: &cell.disposeBag)
//            cell.rejectButton.publisher(for: .touchUpInside)
//                .sink { [weak cell] _ in
//                    guard let cell = cell else { return }
//                    cell.delegate?.notificationTableViewCell(cell, notification: notification, rejectButtonDidPressed: cell.rejectButton)
//                }
//                .store(in: &cell.disposeBag)
//            cell.buttonStackView.isHidden = false
//        } else {
//            cell.buttonStackView.isHidden = true
//        }
//        
//        // configure status (if exist)
//        if let status = notification.status {
//            let frame = CGRect(
//                x: 0,
//                y: 0,
//                width: tableView.readableContentGuide.layoutFrame.width - NotificationStatusTableViewCell.statusPadding.left - NotificationStatusTableViewCell.statusPadding.right,
//                height: tableView.readableContentGuide.layoutFrame.height
//            )
//            StatusSection.configure(
//                cell: cell,
//                tableView: tableView,
//                timelineContext: .notifications,
//                dependency: dependency,
//                readableLayoutFrame: frame,
//                status: status,
//                requestUserID: notification.userID,
//                statusItemAttribute: attribute
//            )
//            cell.statusContainerView.isHidden = false
//            cell.containerStackView.alignment = .top
//            cell.containerStackViewBottomLayoutConstraint.constant = 0
//        } else {
//            if case .followRequest = notification.notificationType {
//                cell.containerStackView.alignment = .top
//            } else {
//                cell.containerStackView.alignment = .center
//            }
//            cell.statusContainerView.isHidden = true
//            cell.containerStackViewBottomLayoutConstraint.constant = 5  // 5pt margin when no status view
//        }
//    }
//    
//    static func configureStatusAccessibilityLabel(cell: NotificationStatusTableViewCell) {
//        // FIXME:
//        cell.accessibilityLabel = {
//            var accessibilityViews: [UIView?] = []
//            accessibilityViews.append(contentsOf: [
//                cell.titleLabel,
//                cell.timestampLabel,
//                cell.statusView
//            ])
//            if !cell.statusContainerView.isHidden {
//                if !cell.statusView.headerContainerView.isHidden {
//                    accessibilityViews.append(cell.statusView.headerInfoLabel)
//                }
//                accessibilityViews.append(contentsOf: [
//                    cell.statusView.nameMetaLabel,
//                    cell.statusView.dateLabel,
//                    cell.statusView.contentMetaText.textView,
//                ])
//            }
//            return accessibilityViews
//                .compactMap { $0?.accessibilityLabel }
//                .joined(separator: " ")
//        }()
//    }
}

