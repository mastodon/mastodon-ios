//
//  ComposeViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import os.log
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
        customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel,
        composeStatusAttachmentCollectionViewCellDelegate: ComposeStatusAttachmentCollectionViewCellDelegate,
        composeStatusPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionCollectionViewCellDelegate,
        composeStatusPollOptionAppendEntryCollectionViewCellDelegate: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate,
        composeStatusPollExpiresOptionCollectionViewCellDelegate: ComposeStatusPollExpiresOptionCollectionViewCellDelegate
    ) {
        // content
        composeStatusContentTableViewCell.metaText.delegate = metaTextDelegate
        composeStatusContentTableViewCell.metaText.textView.delegate = metaTextViewDelegate
        // attachment
        composeStatusAttachmentTableViewCell.composeStatusAttachmentCollectionViewCellDelegate = composeStatusAttachmentCollectionViewCellDelegate
        // poll
        composeStatusPollTableViewCell.delegate = self
        composeStatusPollTableViewCell.customEmojiPickerInputViewModel = customEmojiPickerInputViewModel
        composeStatusPollTableViewCell.composeStatusPollOptionCollectionViewCellDelegate = composeStatusPollOptionCollectionViewCellDelegate
        composeStatusPollTableViewCell.composeStatusPollOptionAppendEntryCollectionViewCellDelegate = composeStatusPollOptionAppendEntryCollectionViewCellDelegate
        composeStatusPollTableViewCell.composeStatusPollExpiresOptionCollectionViewCellDelegate = composeStatusPollExpiresOptionCollectionViewCellDelegate

        // setup data source
        tableView.dataSource = self

        attachmentServices
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] attachmentServices in
                guard let self = self else { return }
                guard self.isViewAppeared else { return }

                let cell = self.composeStatusAttachmentTableViewCell
                guard let dataSource = cell.dataSource else { return }

                var snapshot = NSDiffableDataSourceSnapshot<ComposeStatusAttachmentSection, ComposeStatusAttachmentItem>()
                snapshot.appendSections([.main])
                let items = attachmentServices.map { ComposeStatusAttachmentItem.attachment(attachmentService: $0) }
                snapshot.appendItems(items, toSection: .main)

                tableView.performBatchUpdates {
                    dataSource.apply(snapshot, animatingDifferences: true)
                } completion: { _ in
                    // do nothing
                }
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest(
            isPollComposing,
            pollOptionAttributes
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isPollComposing, pollOptionAttributes in
            guard let self = self else { return }
            guard self.isViewAppeared else { return }

            let cell = self.composeStatusPollTableViewCell
            guard let dataSource = cell.dataSource else { return }

            var snapshot = NSDiffableDataSourceSnapshot<ComposeStatusPollSection, ComposeStatusPollItem>()
            snapshot.appendSections([.main])
            var items: [ComposeStatusPollItem] = []
            if isPollComposing {
                for attribute in pollOptionAttributes {
                    items.append(.pollOption(attribute: attribute))
                }
                if pollOptionAttributes.count < 4 {
                    items.append(.pollOptionAppendEntry)
                }
                items.append(.pollExpiresOption(attribute: self.pollExpiresOptionAttribute))
            }
            snapshot.appendItems(items, toSection: .main)

            tableView.performBatchUpdates {
                dataSource.apply(snapshot, animatingDifferences: true)
            } completion: { _ in
                // do nothing
            }
        }
        .store(in: &disposeBag)
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

// MARK: - UITableViewDataSource
extension ComposeViewModel: UITableViewDataSource {

    enum Section: CaseIterable {
        case repliedTo
        case status
        case attachment
        case poll
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .repliedTo:
            switch composeKind {
            case .reply:        return 1
            default:            return 0
            }
        case .status:           return 1
        case .attachment:
            return 1
        case .poll:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section.allCases[indexPath.section] {
        case .repliedTo:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeRepliedToStatusContentTableViewCell.self), for: indexPath) as! ComposeRepliedToStatusContentTableViewCell
            guard case let .reply(statusObjectID) = composeKind else { return cell }
            cell.framePublisher
                .receive(on: DispatchQueue.main)
                .assign(to: \.value, on: self.repliedToCellFrame)
                .store(in: &cell.disposeBag)
            let managedObjectContext = context.managedObjectContext
            managedObjectContext.performAndWait {
                guard let replyTo = managedObjectContext.object(with: statusObjectID) as? Status else {
                    return
                }
                let status = replyTo.reblog ?? replyTo

                // set avatar
                cell.statusView.configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: status.author.avatarImageURL()))
                // set name username
                cell.statusView.nameLabel.configure(content: status.author.displayNameWithFallback, emojiDict: status.author.emojiDict)
                cell.statusView.usernameLabel.text = "@" + status.author.acct
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
            }
            return cell
        case .status:
            let cell = self.composeStatusContentTableViewCell
            // configure header
            let managedObjectContext = context.managedObjectContext
            managedObjectContext.performAndWait {
                guard case let .reply(replyToStatusObjectID) = self.composeKind,
                      let replyTo = managedObjectContext.object(with: replyToStatusObjectID) as? Status else {
                    cell.statusView.headerContainerView.isHidden = true
                    return
                }
                cell.statusView.headerContainerView.isHidden = false
                cell.statusView.headerIconLabel.attributedText = StatusView.iconAttributedString(image: StatusView.replyIconImage)
                let headerText: String = {
                    let author = replyTo.author
                    let name = author.displayName.isEmpty ? author.username : author.displayName
                    return L10n.Scene.Compose.replyingToUser(name)
                }()
                MastodonStatusContent.parseResult(content: headerText, emojiDict: replyTo.author.emojiDict)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] parseResult in
                        guard let cell = cell else { return }
                        cell.statusView.headerInfoLabel.configure(contentParseResult: parseResult)
                    }
                    .store(in: &cell.disposeBag)
            }
            // configure author
            ComposeStatusSection.configureStatusContent(cell: cell, attribute: composeStatusAttribute)
            // configure content. bind text in UITextViewDelegate
            if let composeContent = composeStatusAttribute.composeContent.value {
                cell.metaText.textView.text = composeContent
            }
            // configure content warning
            cell.statusContentWarningEditorView.textView.text = composeStatusAttribute.contentWarningContent.value
            // bind content warning
            composeStatusAttribute.isContentWarningComposing
                .receive(on: DispatchQueue.main)
                .sink { [weak cell, weak tableView] isContentWarningComposing in
                    guard let cell = cell else { return }
                    guard let tableView = tableView else { return }
                    // self size input cell
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
                .sink { [weak tableView, weak self] text in
                    guard let self = self else { return }
                    // bind input data
                    self.composeStatusAttribute.contentWarningContent.value = text

                    // self size input cell
                    guard let tableView = tableView else { return }
                    UIView.performWithoutAnimation {
                        tableView.beginUpdates()
                        tableView.endUpdates()
                    }
                }
                .store(in: &cell.disposeBag)
            // configure custom emoji picker
            ComposeStatusSection.configureCustomEmojiPicker(viewModel: customEmojiPickerInputViewModel, customEmojiReplaceableTextInput: cell.metaText.textView, disposeBag: &cell.disposeBag)
            ComposeStatusSection.configureCustomEmojiPicker(viewModel: customEmojiPickerInputViewModel, customEmojiReplaceableTextInput: cell.statusContentWarningEditorView.textView, disposeBag: &cell.disposeBag)
            return cell
        case .attachment:
            let cell = self.composeStatusAttachmentTableViewCell
            return cell
        case .poll:
            let cell = self.composeStatusPollTableViewCell
            return cell
        }
    }
}

// MARK: - ComposeStatusPollTableViewCellDelegate
extension ComposeViewModel: ComposeStatusPollTableViewCellDelegate {
    func composeStatusPollTableViewCell(_ cell: ComposeStatusPollTableViewCell, pollOptionAttributesDidReorder options: [ComposeStatusPollItem.PollOptionAttribute]) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        self.pollOptionAttributes.value = options
    }
}
