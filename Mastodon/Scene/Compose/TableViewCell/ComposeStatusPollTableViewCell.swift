//
//  ComposeStatusPollTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-29.
//

import UIKit

protocol ComposeStatusPollTableViewCellDelegate: AnyObject {
    func composeStatusPollTableViewCell(_ cell: ComposeStatusPollTableViewCell, pollOptionAttributesDidReorder options: [ComposeStatusPollItem.PollOptionAttribute])
}

final class ComposeStatusPollTableViewCell: UITableViewCell {

    private(set) var dataSource: UICollectionViewDiffableDataSource<ComposeStatusPollSection, ComposeStatusPollItem>!
    var observations = Set<NSKeyValueObservation>()

    weak var customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel?
    weak var delegate: ComposeStatusPollTableViewCellDelegate?
    weak var composeStatusPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionCollectionViewCellDelegate?
    weak var composeStatusPollOptionAppendEntryCollectionViewCellDelegate: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate?
    weak var composeStatusPollExpiresOptionCollectionViewCellDelegate: ComposeStatusPollExpiresOptionCollectionViewCellDelegate?


    private static func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsetsReference = .readableContent
        return UICollectionViewCompositionalLayout(section: section)
    }

    private(set) var collectionViewHeightLayoutConstraint: NSLayoutConstraint!
    let collectionView: UICollectionView = {
        let collectionViewLayout = ComposeStatusPollTableViewCell.createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(ComposeStatusPollOptionCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollOptionCollectionViewCell.self))
        collectionView.register(ComposeStatusPollOptionAppendEntryCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollOptionAppendEntryCollectionViewCell.self))
        collectionView.register(ComposeStatusPollExpiresOptionCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollExpiresOptionCollectionViewCell.self))
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension ComposeStatusPollTableViewCell {

    private func _init() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        collectionViewHeightLayoutConstraint = collectionView.heightAnchor.constraint(equalToConstant: 300).priority(.defaultHigh)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            collectionViewHeightLayoutConstraint,
        ])

        let longPressReorderGesture = UILongPressGestureRecognizer(target: self, action: #selector(ComposeStatusPollTableViewCell.longPressReorderGestureHandler(_:)))
        collectionView.addGestureRecognizer(longPressReorderGesture)

        collectionView.observe(\.contentSize, options: [.initial, .new]) { [weak self] collectionView, _ in
            guard let self = self else { return }
            print(collectionView.contentSize)
            self.collectionViewHeightLayoutConstraint.constant = collectionView.contentSize.height
        }
        .store(in: &observations)

        self.dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [
                weak self
            ] collectionView, indexPath, item -> UICollectionViewCell? in
            guard let self = self else { return UICollectionViewCell() }

            switch item {
            case .pollOption(let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollOptionCollectionViewCell.self), for: indexPath) as! ComposeStatusPollOptionCollectionViewCell
                cell.pollOptionView.optionTextField.text = attribute.option.value
                cell.pollOptionView.optionTextField.placeholder = L10n.Scene.Compose.Poll.optionNumber(indexPath.item + 1)
                cell.pollOption
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.value, on: attribute.option)
                    .store(in: &cell.disposeBag)
                cell.delegate = self.composeStatusPollOptionCollectionViewCellDelegate
                if let customEmojiPickerInputViewModel = self.customEmojiPickerInputViewModel {
                    ComposeStatusSection.configureCustomEmojiPicker(viewModel: customEmojiPickerInputViewModel, customEmojiReplaceableTextInput: cell.pollOptionView.optionTextField, disposeBag: &cell.disposeBag)
                }
                return cell
            case .pollOptionAppendEntry:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollOptionAppendEntryCollectionViewCell.self), for: indexPath) as! ComposeStatusPollOptionAppendEntryCollectionViewCell
                cell.delegate = self.composeStatusPollOptionAppendEntryCollectionViewCellDelegate
                return cell
            case .pollExpiresOption(let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusPollExpiresOptionCollectionViewCell.self), for: indexPath) as! ComposeStatusPollExpiresOptionCollectionViewCell
                cell.durationButton.setTitle(L10n.Scene.Compose.Poll.durationTime(attribute.expiresOption.value.title), for: .normal)
                attribute.expiresOption
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] expiresOption in
                        guard let cell = cell else { return }
                        cell.durationButton.setTitle(L10n.Scene.Compose.Poll.durationTime(expiresOption.title), for: .normal)
                    }
                    .store(in: &cell.disposeBag)
                cell.delegate = self.composeStatusPollExpiresOptionCollectionViewCellDelegate
                return cell
            }
        }

        dataSource.reorderingHandlers.canReorderItem = { item in
            switch item {
            case .pollOption:       return true
            default:                return false
            }
        }

        // update reordered data source
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }

            let items = transaction.finalSnapshot.itemIdentifiers
            var pollOptionAttributes: [ComposeStatusPollItem.PollOptionAttribute] = []
            for item in items {
                guard case let .pollOption(attribute) = item else { continue }
                pollOptionAttributes.append(attribute)
            }
            self.delegate?.composeStatusPollTableViewCell(self, pollOptionAttributesDidReorder: pollOptionAttributes)
        }
    }

}

extension ComposeStatusPollTableViewCell {

    @objc private func longPressReorderGestureHandler(_ sender: UILongPressGestureRecognizer) {
        switch(sender.state) {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)),
                  let cell = collectionView.cellForItem(at: selectedIndexPath) as? ComposeStatusPollOptionCollectionViewCell else {
                break
            }
            // check if pressing reorder bar no not
            let locationInCell = sender.location(in: cell)
            guard cell.reorderBarImageView.frame.contains(locationInCell) else {
                return
            }

            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)),
                  let dataSource = self.dataSource else {
                break
            }
            guard let item = dataSource.itemIdentifier(for: selectedIndexPath),
                  case .pollOption = item else {
                collectionView.cancelInteractiveMovement()
                return
            }

            var position = sender.location(in: collectionView)
            position.x = collectionView.frame.width * 0.5
            collectionView.updateInteractiveMovementTargetPosition(position)
        case .ended:
            collectionView.endInteractiveMovement()
            collectionView.reloadData()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }

}
