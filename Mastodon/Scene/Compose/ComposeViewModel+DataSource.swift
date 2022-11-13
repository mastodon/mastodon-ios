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
import MetaTextKit
import MastodonMeta
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK

extension ComposeViewModel {

//    func setupDataSource(
//        tableView: UITableView,
//        metaTextDelegate: MetaTextDelegate,
//        metaTextViewDelegate: UITextViewDelegate,
//        customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel,
//        composeStatusAttachmentCollectionViewCellDelegate: ComposeStatusAttachmentCollectionViewCellDelegate,
//        composeStatusPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionCollectionViewCellDelegate,
//        composeStatusPollOptionAppendEntryCollectionViewCellDelegate: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate,
//        composeStatusPollExpiresOptionCollectionViewCellDelegate: ComposeStatusPollExpiresOptionCollectionViewCellDelegate
//    ) {
//        // UI
//        bind()
//
//        // content
//        bind(cell: composeStatusContentTableViewCell, tableView: tableView)
//        composeStatusContentTableViewCell.metaText.delegate = metaTextDelegate
//        composeStatusContentTableViewCell.metaText.textView.delegate = metaTextViewDelegate
//
//        // attachment
//        bind(cell: composeStatusAttachmentTableViewCell, tableView: tableView)
//        composeStatusAttachmentTableViewCell.composeStatusAttachmentCollectionViewCellDelegate = composeStatusAttachmentCollectionViewCellDelegate
//
//        // poll
//        bind(cell: composeStatusPollTableViewCell, tableView: tableView)
//        composeStatusPollTableViewCell.delegate = self
//        composeStatusPollTableViewCell.customEmojiPickerInputViewModel = customEmojiPickerInputViewModel
//        composeStatusPollTableViewCell.composeStatusPollOptionCollectionViewCellDelegate = composeStatusPollOptionCollectionViewCellDelegate
//        composeStatusPollTableViewCell.composeStatusPollOptionAppendEntryCollectionViewCellDelegate = composeStatusPollOptionAppendEntryCollectionViewCellDelegate
//        composeStatusPollTableViewCell.composeStatusPollExpiresOptionCollectionViewCellDelegate = composeStatusPollExpiresOptionCollectionViewCellDelegate
//
//        // setup data source
//        tableView.dataSource = self
//    }
    
}

//// MARK: - UITableViewDataSource
//extension ComposeViewModel: UITableViewDataSource {

//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        switch Section.allCases[indexPath.section] {
//        case .repliedTo:
//            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeRepliedToStatusContentTableViewCell.self), for: indexPath) as! ComposeRepliedToStatusContentTableViewCell
//            guard case let .reply(record) = composeKind else { return cell }
//
//            // bind frame publisher
//            cell.framePublisher
//                .receive(on: DispatchQueue.main)
//                .assign(to: \.repliedToCellFrame, on: self)
//                .store(in: &cell.disposeBag)
//
//            // set initial width
//            if cell.statusView.frame.width == .zero {
//                cell.statusView.frame.size.width = tableView.frame.width
//            }
//
//            // configure status
//            context.managedObjectContext.performAndWait {
//                guard let replyTo = record.object(in: context.managedObjectContext) else { return }
//                cell.statusView.configure(status: replyTo)
//            }
//
//            return cell
//        case .status:
//            return composeStatusContentTableViewCell
//        case .attachment:
//            return composeStatusAttachmentTableViewCell
//        case .poll:
//            return composeStatusPollTableViewCell
//        }
//    }
//}

//// MARK: - ComposeStatusPollTableViewCellDelegate
//extension ComposeViewModel: ComposeStatusPollTableViewCellDelegate {
//    func composeStatusPollTableViewCell(_ cell: ComposeStatusPollTableViewCell, pollOptionAttributesDidReorder options: [ComposeStatusPollItem.PollOptionAttribute]) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//
//        self.pollOptionAttributes = options
//    }
//}
//
//extension ComposeViewModel {
//    private func bind() {
//        $isCustomEmojiComposing
//            .assign(to: \.value, on: customEmojiPickerInputViewModel.isCustomEmojiComposing)
//            .store(in: &disposeBag)
//            
//        $isContentWarningComposing
//            .assign(to: \.isContentWarningComposing, on: composeStatusAttribute)
//            .store(in: &disposeBag)
//        
//        // bind compose toolbar UI state
//        Publishers.CombineLatest(
//            $isPollComposing,
//            $attachmentServices
//        )
//        .receive(on: DispatchQueue.main)
//        .sink(receiveValue: { [weak self] isPollComposing, attachmentServices in
//            guard let self = self else { return }
//            let shouldMediaDisable = isPollComposing || attachmentServices.count >= self.maxMediaAttachments
//            let shouldPollDisable = attachmentServices.count > 0
//
//            self.isMediaToolbarButtonEnabled = !shouldMediaDisable
//            self.isPollToolbarButtonEnabled = !shouldPollDisable
//        })
//        .store(in: &disposeBag)
//        
//        // calculate `Idempotency-Key`
//        let content = Publishers.CombineLatest3(
//            composeStatusAttribute.$isContentWarningComposing,
//            composeStatusAttribute.$contentWarningContent,
//            composeStatusAttribute.$composeContent
//        )
//        .map { isContentWarningComposing, contentWarningContent, composeContent -> String in
//            if isContentWarningComposing {
//                return contentWarningContent + (composeContent ?? "")
//            } else {
//                return composeContent ?? ""
//            }
//        }
//        let attachmentIDs = $attachmentServices.map { attachments -> String in
//            let attachmentIDs = attachments.compactMap { $0.attachment.value?.id }
//            return attachmentIDs.joined(separator: ",")
//        }
//        let pollOptionsAndDuration = Publishers.CombineLatest3(
//            $isPollComposing,
//            $pollOptionAttributes,
//            pollExpiresOptionAttribute.expiresOption
//        )
//        .map { isPollComposing, pollOptionAttributes, expiresOption -> String in
//            guard isPollComposing else {
//                return ""
//            }
//            
//            let pollOptions = pollOptionAttributes.map { $0.option.value }.joined(separator: ",")
//            return pollOptions + expiresOption.rawValue
//        }
//        
//        Publishers.CombineLatest4(
//            content,
//            attachmentIDs,
//            pollOptionsAndDuration,
//            $selectedStatusVisibility
//        )
//            .map { content, attachmentIDs, pollOptionsAndDuration, selectedStatusVisibility -> String in
//                var hasher = Hasher()
//                hasher.combine(content)
//                hasher.combine(attachmentIDs)
//                hasher.combine(pollOptionsAndDuration)
//                hasher.combine(selectedStatusVisibility.visibility.rawValue)
//                let hashValue = hasher.finalize()
//                return "\(hashValue)"
//            }
//            .assign(to: \.value, on: idempotencyKey)
//            .store(in: &disposeBag)
//        
//        // bind modal dismiss state
//        composeStatusAttribute.$composeContent
//            .receive(on: DispatchQueue.main)
//            .map { [weak self] content in
//                let content = content ?? ""
//                if content.isEmpty {
//                    return true
//                }
//                // if preInsertedContent plus a space is equal to the content, simply dismiss the modal
//                if let preInsertedContent = self?.preInsertedContent {
//                    return content == preInsertedContent
//                }
//                return false
//            }
//            .assign(to: &$shouldDismiss)
//        
//        // bind compose bar button item UI state
//        let isComposeContentEmpty = composeStatusAttribute.$composeContent
//            .map { ($0 ?? "").isEmpty }
//        let isComposeContentValid = $characterCount
//            .compactMap { [weak self] characterCount -> Bool in
//                guard let self = self else { return characterCount <= 500 }
//                return characterCount <= self.composeContentLimit
//            }
//        let isMediaEmpty = $attachmentServices
//            .map { $0.isEmpty }
//        let isMediaUploadAllSuccess = $attachmentServices
//            .map { services in
//                services.allSatisfy { $0.uploadStateMachineSubject.value is MastodonAttachmentService.UploadState.Finish }
//            }
//        let isPollAttributeAllValid = $pollOptionAttributes
//            .map { pollAttributes in
//                pollAttributes.allSatisfy { attribute -> Bool in
//                    !attribute.option.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//                }
//            }
//        
//        let isPublishBarButtonItemEnabledPrecondition1 = Publishers.CombineLatest4(
//            isComposeContentEmpty,
//            isComposeContentValid,
//            isMediaEmpty,
//            isMediaUploadAllSuccess
//        )
//        .map { isComposeContentEmpty, isComposeContentValid, isMediaEmpty, isMediaUploadAllSuccess -> Bool in
//            if isMediaEmpty {
//                return isComposeContentValid && !isComposeContentEmpty
//            } else {
//                return isComposeContentValid && isMediaUploadAllSuccess
//            }
//        }
//        .eraseToAnyPublisher()
//        
//        let isPublishBarButtonItemEnabledPrecondition2 = Publishers.CombineLatest4(
//            isComposeContentEmpty,
//            isComposeContentValid,
//            $isPollComposing,
//            isPollAttributeAllValid
//        )
//        .map { isComposeContentEmpty, isComposeContentValid, isPollComposing, isPollAttributeAllValid -> Bool in
//            if isPollComposing {
//                return isComposeContentValid && !isComposeContentEmpty && isPollAttributeAllValid
//            } else {
//                return isComposeContentValid && !isComposeContentEmpty
//            }
//        }
//        .eraseToAnyPublisher()
//        
//        Publishers.CombineLatest(
//            isPublishBarButtonItemEnabledPrecondition1,
//            isPublishBarButtonItemEnabledPrecondition2
//        )
//        .map { $0 && $1 }
//        .assign(to: &$isPublishBarButtonItemEnabled)
//    }
//}
//
//extension ComposeViewModel {
//    private func bind(
//        cell: ComposeStatusContentTableViewCell,
//        tableView: UITableView
//    ) {
//        // bind status content character count
//        Publishers.CombineLatest3(
//            composeStatusAttribute.$composeContent,
//            composeStatusAttribute.$isContentWarningComposing,
//            composeStatusAttribute.$contentWarningContent
//        )
//        .map { composeContent, isContentWarningComposing, contentWarningContent -> Int in
//            let composeContent = composeContent ?? ""
//            var count = composeContent.count
//            if isContentWarningComposing {
//                count += contentWarningContent.count
//            }
//            return count
//        }
//        .assign(to: &$characterCount)
//        
//        // bind content warning
//        composeStatusAttribute.$isContentWarningComposing
//            .receive(on: DispatchQueue.main)
//            .sink { [weak cell, weak tableView] isContentWarningComposing in
//                guard let cell = cell else { return }
//                guard let tableView = tableView else { return }
//                
//                // self size input cell
//                cell.statusContentWarningEditorView.isHidden = !isContentWarningComposing
//                cell.statusContentWarningEditorView.alpha = 0
//                UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseOut]) {
//                    cell.statusContentWarningEditorView.alpha = 1
//                    tableView.beginUpdates()
//                    tableView.endUpdates()
//                } completion: { _ in
//                    // do nothing
//                }
//            }
//            .store(in: &disposeBag)
//        
//        cell.contentWarningContent
//            .removeDuplicates()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak tableView, weak self] text in
//                guard let self = self else { return }
//                // bind input data
//                self.composeStatusAttribute.contentWarningContent = text
//
//                // self size input cell
//                guard let tableView = tableView else { return }
//                UIView.performWithoutAnimation {
//                    tableView.beginUpdates()
//                    tableView.endUpdates()
//                }
//            }
//            .store(in: &cell.disposeBag)
//        
//        // configure custom emoji picker
//        ComposeStatusSection.configureCustomEmojiPicker(
//            viewModel: customEmojiPickerInputViewModel,
//            customEmojiReplaceableTextInput: cell.metaText.textView,
//            disposeBag: &disposeBag
//        )
//        ComposeStatusSection.configureCustomEmojiPicker(
//            viewModel: customEmojiPickerInputViewModel,
//            customEmojiReplaceableTextInput: cell.statusContentWarningEditorView.textView,
//            disposeBag: &disposeBag
//        )
//    }
//}
//
//extension ComposeViewModel {
//    private func bind(
//        cell: ComposeStatusPollTableViewCell,
//        tableView: UITableView
//    ) {
//        Publishers.CombineLatest(
//            $isPollComposing,
//            $pollOptionAttributes
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] isPollComposing, pollOptionAttributes in
//            guard let self = self else { return }
//            guard self.isViewAppeared else { return }
//
//            let cell = self.composeStatusPollTableViewCell
//            guard let dataSource = cell.dataSource else { return }
//
//            var snapshot = NSDiffableDataSourceSnapshot<ComposeStatusPollSection, ComposeStatusPollItem>()
//            snapshot.appendSections([.main])
//            var items: [ComposeStatusPollItem] = []
//            if isPollComposing {
//                for attribute in pollOptionAttributes {
//                    items.append(.pollOption(attribute: attribute))
//                }
//                if pollOptionAttributes.count < self.maxPollOptions {
//                    items.append(.pollOptionAppendEntry)
//                }
//                items.append(.pollExpiresOption(attribute: self.pollExpiresOptionAttribute))
//            }
//            snapshot.appendItems(items, toSection: .main)
//
//            tableView.performBatchUpdates {
//                if #available(iOS 15.0, *) {
//                    dataSource.apply(snapshot, animatingDifferences: false)
//                } else {
//                    dataSource.apply(snapshot, animatingDifferences: true)
//                }
//            }
//        }
//        .store(in: &disposeBag)
//        
//        // bind delegate
//        $pollOptionAttributes
//            .sink { [weak self] pollAttributes in
//                guard let self = self else { return }
//                pollAttributes.forEach { $0.delegate = self }
//            }
//            .store(in: &disposeBag)
//    }
//}
//
//extension ComposeViewModel {
//    private func bind(
//        cell: ComposeStatusAttachmentTableViewCell,
//        tableView: UITableView
//    ) {
//        cell.collectionViewHeightDidUpdate
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                guard let _ = self else { return }
//                tableView.beginUpdates()
//                tableView.endUpdates()
//            }
//            .store(in: &disposeBag)
//
//        $attachmentServices
//            .removeDuplicates()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] attachmentServices in
//                guard let self = self else { return }
//                guard self.isViewAppeared else { return }
//
//                let cell = self.composeStatusAttachmentTableViewCell
//                guard let dataSource = cell.dataSource else { return }
//
//                var snapshot = NSDiffableDataSourceSnapshot<ComposeStatusAttachmentSection, ComposeStatusAttachmentItem>()
//                snapshot.appendSections([.main])
//                let items = attachmentServices.map { ComposeStatusAttachmentItem.attachment(attachmentService: $0) }
//                snapshot.appendItems(items, toSection: .main)
//
//                if #available(iOS 15.0, *) {
//                    dataSource.applySnapshotUsingReloadData(snapshot)
//                } else {
//                    dataSource.apply(snapshot, animatingDifferences: false)
//                }
//            }
//            .store(in: &disposeBag)
//        
//        // setup attribute updater
//        $attachmentServices
//            .receive(on: DispatchQueue.main)
//            .debounce(for: 0.3, scheduler: DispatchQueue.main)
//            .sink { attachmentServices in
//                // drive service upload state
//                // make image upload in the queue
//                for attachmentService in attachmentServices {
//                    // skip when prefix N task when task finish OR fail OR uploading
//                    guard let currentState = attachmentService.uploadStateMachine.currentState else { break }
//                    if currentState is MastodonAttachmentService.UploadState.Fail {
//                        continue
//                    }
//                    if currentState is MastodonAttachmentService.UploadState.Finish {
//                        continue
//                    }
//                    if currentState is MastodonAttachmentService.UploadState.Processing {
//                        continue
//                    }
//                    if currentState is MastodonAttachmentService.UploadState.Uploading {
//                        break
//                    }
//                    // trigger uploading one by one
//                    if currentState is MastodonAttachmentService.UploadState.Initial {
//                        attachmentService.uploadStateMachine.enter(MastodonAttachmentService.UploadState.Uploading.self)
//                        break
//                    }
//                }
//            }
//            .store(in: &disposeBag)
//        
//        // bind delegate
//        $attachmentServices
//            .sink { [weak self] attachmentServices in
//                guard let self = self else { return }
//                attachmentServices.forEach { $0.delegate = self }
//            }
//            .store(in: &disposeBag)
//    }
//}
