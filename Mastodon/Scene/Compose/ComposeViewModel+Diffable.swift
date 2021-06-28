//
//  ComposeViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import Combine
import CoreDataStack
import TwitterTextEditor
import MastodonSDK
import MastodonMeta
import MetaTextView

extension ComposeViewModel {

    func setupDiffableDataSource(
        tableView: UITableView,
        metaTextDelegate: MetaTextDelegate,
        metaTextViewDelegate: UITextViewDelegate,
        customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel
    ) {
        let dataSource = UITableViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem>(tableView: tableView) { [
            weak self,
            weak metaTextDelegate,
            weak metaTextViewDelegate,
            weak customEmojiPickerInputViewModel
        ] tableView, indexPath, item in
            guard let self = self else { return UITableViewCell() }
            let managedObjectContext = self.context.managedObjectContext

            switch item {
            case .replyTo(let statusObjectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeRepliedToStatusContentTableViewCell.self), for: indexPath) as! ComposeRepliedToStatusContentTableViewCell
                managedObjectContext.performAndWait {
                    guard let replyTo = managedObjectContext.object(with: statusObjectID) as? Status else {
                        return
                    }
                    let status = replyTo.reblog ?? replyTo

                    // set avatar
                    cell.statusView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: status.author.avatarImageURL()))
                    // set name username
                    cell.statusView.nameLabel.text = {
                        let author = status.author
                        return author.displayName.isEmpty ? author.username : author.displayName
                    }()
                    cell.statusView.usernameLabel.text = "@" + (status.reblog ?? status).author.acct
                    // set text
                    let content = MastodonContent(content: status.content, emojis: status.emojiMeta)
                    do {
                        let metaContent = try MastodonMetaContent.convert(document: content)
                        cell.statusView.contentMetaText.configure(content: metaContent)
                    } catch {
                        cell.statusView.contentMetaText.textView.text = " "
                        assertionFailure()
                    }
                    // set date
                    cell.statusView.dateLabel.text = status.createdAt.slowedTimeAgoSinceNow

                    cell.framePublisher
                        .assign(to: \.value, on: self.repliedToCellFrame)
                        .store(in: &cell.disposeBag)
                }
                return cell
            case .input(let replyToStatusObjectID, let attribute):
                let cell = self.composeStatusContentTableViewCell
                // configure header
                managedObjectContext.performAndWait {
                    guard let replyToStatusObjectID = replyToStatusObjectID,
                          let replyTo = managedObjectContext.object(with: replyToStatusObjectID) as? Status else {
                        cell.statusView.headerContainerView.isHidden = true
                        return
                    }
                    cell.statusView.headerContainerView.isHidden = false
                    cell.statusView.headerIconLabel.attributedText = StatusView.iconAttributedString(image: StatusView.replyIconImage)
                    cell.statusView.headerInfoLabel.text = L10n.Scene.Compose.replyingToUser(replyTo.author.displayNameWithFallback)
                }
                // configure author
                ComposeStatusSection.configureStatusContent(cell: cell, attribute: attribute)
                // bind content warning
                attribute.isContentWarningComposing
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell, weak tableView] isContentWarningComposing in
                        guard let cell = cell else { return }
                        guard let tableView = tableView else { return }
                        // self size input cell
                        //tableView.
                        cell.statusContentWarningEditorView.isHidden = !isContentWarningComposing
                        cell.statusContentWarningEditorView.alpha = 0
                        UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseOut]) {
                            cell.statusContentWarningEditorView.alpha = 1
                        } completion: { _ in
                            // do nothing
                        }
                    }
                    .store(in: &cell.disposeBag)
                cell.contentWarningContent
                    .removeDuplicates()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak tableView] text in
                        guard let tableView = tableView else { return }
                        // self size input cell
                        UIView.performWithoutAnimation {
                            tableView.beginUpdates()
                            tableView.endUpdates()
                        }
                        // bind input data
                        attribute.contentWarningContent.value = text
                    }
                    .store(in: &cell.disposeBag)
                // configure custom emoji picker
                ComposeStatusSection.configureCustomEmojiPicker(viewModel: customEmojiPickerInputViewModel, customEmojiReplaceableTextInput: cell.metaText.textView, disposeBag: &cell.disposeBag)
                ComposeStatusSection.configureCustomEmojiPicker(viewModel: customEmojiPickerInputViewModel, customEmojiReplaceableTextInput: cell.statusContentWarningEditorView.textView, disposeBag: &cell.disposeBag)
                // setup delegate
                cell.metaText.delegate = metaTextDelegate
                cell.metaText.textView.delegate = metaTextViewDelegate

                return cell
            case .attachment(let attachmentService):
                return UITableViewCell()
            case .pollOption, .pollOptionAppendEntry, .pollExpiresOption:
                return UITableViewCell()
            }
        }
        self.dataSource = dataSource

        var snapshot = NSDiffableDataSourceSnapshot<ComposeStatusSection, ComposeStatusItem>()
        snapshot.appendSections([.repliedTo, .status, .attachment, .poll])
        switch composeKind {
        case .reply(let statusObjectID):
            snapshot.appendItems([.replyTo(statusObjectID: statusObjectID)], toSection: .repliedTo)
            snapshot.appendItems([.input(replyToStatusObjectID: statusObjectID, attribute: composeStatusAttribute)], toSection: .repliedTo)
        case .hashtag, .mention, .post:
            snapshot.appendItems([.input(replyToStatusObjectID: nil, attribute: composeStatusAttribute)], toSection: .status)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func setupDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency,
        customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel,
        metaTextDelegate: MetaTextDelegate,
        metaTextViewDelegate: UITextViewDelegate,
        composeStatusAttachmentTableViewCellDelegate: ComposeStatusAttachmentCollectionViewCellDelegate,
        composeStatusPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionCollectionViewCellDelegate,
        composeStatusNewPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate,
        composeStatusPollExpiresOptionCollectionViewCellDelegate: ComposeStatusPollExpiresOptionCollectionViewCellDelegate
    ) {
        let diffableDataSource = ComposeStatusSection.collectionViewDiffableDataSource(
            for: collectionView,
            dependency: dependency,
            managedObjectContext: context.managedObjectContext,
            composeKind: composeKind,
            repliedToCellFrameSubscriber: repliedToCellFrame,
            customEmojiPickerInputViewModel: customEmojiPickerInputViewModel,
            metaTextDelegate: metaTextDelegate,
            metaTextViewDelegate: metaTextViewDelegate,
            composeStatusAttachmentTableViewCellDelegate: composeStatusAttachmentTableViewCellDelegate,
            composeStatusPollOptionCollectionViewCellDelegate: composeStatusPollOptionCollectionViewCellDelegate,
            composeStatusNewPollOptionCollectionViewCellDelegate: composeStatusNewPollOptionCollectionViewCellDelegate,
            composeStatusPollExpiresOptionCollectionViewCellDelegate: composeStatusPollExpiresOptionCollectionViewCellDelegate
        )

        diffableDataSource.reorderingHandlers.canReorderItem = { item in
            switch item {
            case .pollOption:       return true
            default:                return false
            }
        }
        
        // update reordered data source
        diffableDataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
        
            let items = transaction.finalSnapshot.itemIdentifiers
            var pollOptionAttributes: [ComposeStatusItem.ComposePollOptionAttribute] = []
            for item in items {
                guard case let .pollOption(attribute) = item else { continue }
                pollOptionAttributes.append(attribute)
            }
            self.pollOptionAttributes.value = pollOptionAttributes
        }
    
        self.diffableDataSource = diffableDataSource
        var snapshot = NSDiffableDataSourceSnapshot<ComposeStatusSection, ComposeStatusItem>()
        snapshot.appendSections([.repliedTo, .status, .attachment, .poll])
        switch composeKind {
        case .reply(let statusObjectID):
            snapshot.appendItems([.replyTo(statusObjectID: statusObjectID)], toSection: .repliedTo)
            snapshot.appendItems([.input(replyToStatusObjectID: statusObjectID, attribute: composeStatusAttribute)], toSection: .repliedTo)
        case .hashtag, .mention, .post:
            snapshot.appendItems([.input(replyToStatusObjectID: nil, attribute: composeStatusAttribute)], toSection: .status)
        }
        diffableDataSource.apply(snapshot, animatingDifferences: false)
        
        // some magic fix modal presentation animation issue
        collectionView.dataSource = diffableDataSource
    }
    
    func setupCustomEmojiPickerDiffableDataSource(
        for collectionView: UICollectionView,
        dependency: NeedsDependency
    ) {
        let diffableDataSource = CustomEmojiPickerSection.collectionViewDiffableDataSource(
            for: collectionView,
            dependency: dependency
        )
        self.customEmojiPickerDiffableDataSource = diffableDataSource
        
        customEmojiViewModel
            .sink { [weak self, weak diffableDataSource] customEmojiViewModel in
                guard let self = self else { return }
                guard let diffableDataSource = diffableDataSource else { return }
                guard let customEmojiViewModel = customEmojiViewModel else {
                    self.customEmojiViewModelSubscription = nil
                    let snapshot = NSDiffableDataSourceSnapshot<CustomEmojiPickerSection, CustomEmojiPickerItem>()
                    diffableDataSource.apply(snapshot)
                    return
                }

                self.customEmojiViewModelSubscription = customEmojiViewModel.emojis
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self, weak diffableDataSource] emojis in
                        guard let _ = self else { return }
                        guard let diffableDataSource = diffableDataSource else { return }
                        var snapshot = NSDiffableDataSourceSnapshot<CustomEmojiPickerSection, CustomEmojiPickerItem>()
                        let customEmojiSection = CustomEmojiPickerSection.emoji(name: customEmojiViewModel.domain.uppercased())
                        snapshot.appendSections([customEmojiSection])
                        let items: [CustomEmojiPickerItem] = {
                            var items = [CustomEmojiPickerItem]()
                            for emoji in emojis where emoji.visibleInPicker {
                                let attribute = CustomEmojiPickerItem.CustomEmojiAttribute(emoji: emoji)
                                let item = CustomEmojiPickerItem.emoji(attribute: attribute)
                                items.append(item)
                            }
                            return items
                        }()
                        snapshot.appendItems(items, toSection: customEmojiSection)
                        diffableDataSource.apply(snapshot)
                    }
            }
            .store(in: &disposeBag)
    }
    
}
