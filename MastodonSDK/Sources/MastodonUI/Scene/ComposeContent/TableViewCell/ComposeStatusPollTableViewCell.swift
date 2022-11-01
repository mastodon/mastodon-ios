//
//  ComposeStatusPollTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-29.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonLocalization

//protocol ComposeStatusPollTableViewCellDelegate: AnyObject {
//    func composeStatusPollTableViewCell(_ cell: ComposeStatusPollTableViewCell, pollOptionAttributesDidReorder options: [ComposeStatusPollItem.PollOptionAttribute])
//}
//
//final class ComposeStatusPollTableViewCell: UITableViewCell {
//    
//    let logger = Logger(subsystem: "ComposeStatusPollTableViewCell", category: "UI")
//
//    private(set) var dataSource: UICollectionViewDiffableDataSource<ComposeStatusPollSection, ComposeStatusPollItem>!
//    var observations = Set<NSKeyValueObservation>()
//
//    weak var customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel?
//    weak var delegate: ComposeStatusPollTableViewCellDelegate?
//    weak var composeStatusPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionCollectionViewCellDelegate?
//    weak var composeStatusPollOptionAppendEntryCollectionViewCellDelegate: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate?
//    weak var composeStatusPollExpiresOptionCollectionViewCellDelegate: ComposeStatusPollExpiresOptionCollectionViewCellDelegate?
//
//    private static func createLayout() -> UICollectionViewLayout {
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
//        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
//        let section = NSCollectionLayoutSection(group: group)
//        section.contentInsetsReference = .readableContent
//        return UICollectionViewCompositionalLayout(section: section)
//    }
//
//    private(set) var collectionViewHeightLayoutConstraint: NSLayoutConstraint!
//    let collectionView: UICollectionView = {
//        let collectionViewLayout = ComposeStatusPollTableViewCell.createLayout()
//        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
//        collectionView.register(ComposeStatusPollOptionCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollOptionCollectionViewCell.self))
//        collectionView.register(ComposeStatusPollOptionAppendEntryCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollOptionAppendEntryCollectionViewCell.self))
//        collectionView.register(ComposeStatusPollExpiresOptionCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollExpiresOptionCollectionViewCell.self))
//        collectionView.backgroundColor = .clear
//        collectionView.alwaysBounceVertical = true
//        collectionView.isScrollEnabled = false
//        collectionView.dragInteractionEnabled = true
//        return collectionView
//    }()
//    let collectionViewHeightDidUpdate = PassthroughSubject<Void, Never>()
//
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        _init()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        _init()
//    }
//
//}
//
//extension ComposeStatusPollTableViewCell {
//
//    private func _init() {
//        backgroundColor = .clear
//        contentView.backgroundColor = .clear
//
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(collectionView)
//        collectionViewHeightLayoutConstraint = collectionView.heightAnchor.constraint(equalToConstant: 300).priority(.defaultHigh)
//        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            collectionViewHeightLayoutConstraint,
//        ])
//
//        collectionView.observe(\.contentSize, options: [.initial, .new]) { [weak self] collectionView, _ in
//            guard let self = self else { return }
//            self.collectionViewHeightLayoutConstraint.constant = collectionView.contentSize.height
//            self.collectionViewHeightDidUpdate.send()
//        }
//        .store(in: &observations)
//
//        self.dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [
//                weak self
//            ] collectionView, indexPath, item -> UICollectionViewCell? in
//            guard let self = self else { return UICollectionViewCell() }
//
//            switch item {
//            case .pollOption(let attribute):
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollOptionCollectionViewCell.self), for: indexPath) as! ComposeStatusPollOptionCollectionViewCell
//                cell.pollOptionView.optionTextField.text = attribute.option.value
//                cell.pollOptionView.optionTextField.placeholder = L10n.Scene.Compose.Poll.optionNumber(indexPath.item + 1)
//                cell.pollOption
//                    .receive(on: DispatchQueue.main)
//                    .assign(to: \.value, on: attribute.option)
//                    .store(in: &cell.disposeBag)
//                cell.delegate = self.composeStatusPollOptionCollectionViewCellDelegate
//                if let customEmojiPickerInputViewModel = self.customEmojiPickerInputViewModel {
//                    ComposeStatusSection.configureCustomEmojiPicker(viewModel: customEmojiPickerInputViewModel, customEmojiReplaceableTextInput: cell.pollOptionView.optionTextField, disposeBag: &cell.disposeBag)
//                }
//                return cell
//            case .pollOptionAppendEntry:
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollOptionAppendEntryCollectionViewCell.self), for: indexPath) as! ComposeStatusPollOptionAppendEntryCollectionViewCell
//                cell.delegate = self.composeStatusPollOptionAppendEntryCollectionViewCellDelegate
//                return cell
//            case .pollExpiresOption(let attribute):
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollExpiresOptionCollectionViewCell.self), for: indexPath) as! ComposeStatusPollExpiresOptionCollectionViewCell
//                cell.durationButton.setTitle(L10n.Scene.Compose.Poll.durationTime(attribute.expiresOption.value.title), for: .normal)
//                attribute.expiresOption
//                    .receive(on: DispatchQueue.main)
//                    .sink { [weak cell] expiresOption in
//                        guard let cell = cell else { return }
//                        cell.durationButton.setTitle(L10n.Scene.Compose.Poll.durationTime(expiresOption.title), for: .normal)
//                    }
//                    .store(in: &cell.disposeBag)
//                cell.delegate = self.composeStatusPollExpiresOptionCollectionViewCellDelegate
//                return cell
//            }
//        }
//        
//        collectionView.dragDelegate = self
//        collectionView.dropDelegate = self
//    }
//
//}
//
//// MARK: - UICollectionViewDragDelegate
//extension ComposeStatusPollTableViewCell: UICollectionViewDragDelegate {
//    
//    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
//        guard let item = dataSource.itemIdentifier(for: indexPath) else { return [] }
//        switch item {
//        case .pollOption:
//            let itemProvider = NSItemProvider(object: String(item.hashValue) as NSString)
//            let dragItem = UIDragItem(itemProvider: itemProvider)
//            dragItem.localObject = item
//            return [dragItem]
//        default:
//            return []
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
//        // drag to app should be the same app
//        return true
//    }
//}
//
//// MARK: - UICollectionViewDropDelegate
//extension ComposeStatusPollTableViewCell: UICollectionViewDropDelegate {
//    // didUpdate
//    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
//        guard collectionView.hasActiveDrag,
//              let destinationIndexPath = destinationIndexPath,
//              let item = dataSource.itemIdentifier(for: destinationIndexPath)
//        else {
//            return UICollectionViewDropProposal(operation: .forbidden)
//        }
//        
//        switch item {
//        case .pollOption:
//            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
//        default:
//            return UICollectionViewDropProposal(operation: .cancel)
//        }
//    }
//    
//    // performDrop
//    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
//        guard let dropItem = coordinator.items.first,
//              let item = dropItem.dragItem.localObject as? ComposeStatusPollItem,
//              case .pollOption = item
//        else { return }
//
//        guard coordinator.proposal.operation == .move else { return }
//        guard let destinationIndexPath = coordinator.destinationIndexPath,
//              let _ = collectionView.cellForItem(at: destinationIndexPath) as? ComposeStatusPollOptionCollectionViewCell
//        else { return }
//        
//        var snapshot = dataSource.snapshot()
//        guard destinationIndexPath.row < snapshot.itemIdentifiers.count else { return }
//        let anchorItem = snapshot.itemIdentifiers[destinationIndexPath.row]
//        snapshot.moveItem(item, afterItem: anchorItem)
//        dataSource.apply(snapshot)
//        
//        coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
//    }
//}
//
//extension ComposeStatusPollTableViewCell: UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(originalIndexPath.debugDescription) -> \(proposedIndexPath.debugDescription)")
//        
//        guard let _ = collectionView.cellForItem(at: proposedIndexPath) as? ComposeStatusPollOptionCollectionViewCell else {
//            return originalIndexPath
//        }
//        
//        return proposedIndexPath
//    }
//}
