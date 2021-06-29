//
//  ComposeStatusAttachmentTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-29.
//

import UIKit
import Combine
import AlamofireImage

final class ComposeStatusAttachmentTableViewCell: UITableViewCell {

    private(set) var dataSource: UICollectionViewDiffableDataSource<ComposeStatusAttachmentSection, ComposeStatusAttachmentItem>!
    weak var composeStatusAttachmentCollectionViewCellDelegate: ComposeStatusAttachmentCollectionViewCellDelegate?
    var observations = Set<NSKeyValueObservation>()

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
    let collectionView: ComposeCollectionView = {
        let collectionViewLayout = ComposeStatusAttachmentTableViewCell.createLayout()
        let collectionView = ComposeCollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(ComposeStatusAttachmentCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusAttachmentCollectionViewCell.self))
        collectionView.backgroundColor = Asset.Scene.Compose.background.color
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

extension ComposeStatusAttachmentTableViewCell {

    private func _init() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        collectionViewHeightLayoutConstraint = collectionView.heightAnchor.constraint(equalToConstant: 200).priority(.defaultHigh)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            collectionViewHeightLayoutConstraint,
        ])

        collectionView.observe(\.contentSize, options: [.initial, .new]) { [weak self] collectionView, _ in
            guard let self = self else { return }
            self.collectionViewHeightLayoutConstraint.constant = collectionView.contentSize.height
        }
        .store(in: &observations)

        self.dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [
                weak self
            ] collectionView, indexPath, item -> UICollectionViewCell? in
            guard let self = self else { return UICollectionViewCell() }
            switch item {
            case .attachment(let attachmentService):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeStatusAttachmentCollectionViewCell.self), for: indexPath) as! ComposeStatusAttachmentCollectionViewCell
                cell.attachmentContainerView.descriptionTextView.text = attachmentService.description.value
                cell.delegate = self.composeStatusAttachmentCollectionViewCellDelegate
                attachmentService.thumbnailImage
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] thumbnailImage in
                        guard let cell = cell else { return }
                        let size = cell.attachmentContainerView.previewImageView.frame.size != .zero ? cell.attachmentContainerView.previewImageView.frame.size : CGSize(width: 1, height: 1)
                        guard let image = thumbnailImage else {
                            let placeholder = UIImage.placeholder(
                                size: size,
                                color: Asset.Colors.Background.systemGroupedBackground.color
                            )
                            .af.imageRounded(
                                withCornerRadius: AttachmentContainerView.containerViewCornerRadius
                            )
                            cell.attachmentContainerView.previewImageView.image = placeholder
                            return
                        }
                        cell.attachmentContainerView.previewImageView.image = image
                            .af.imageAspectScaled(toFill: size)
                            .af.imageRounded(withCornerRadius: AttachmentContainerView.containerViewCornerRadius)
                    }
                    .store(in: &cell.disposeBag)
                Publishers.CombineLatest(
                    attachmentService.uploadStateMachineSubject.eraseToAnyPublisher(),
                    attachmentService.error.eraseToAnyPublisher()
                )
                .receive(on: DispatchQueue.main)
                .sink { [weak cell, weak attachmentService] uploadState, error  in
                    guard let cell = cell else { return }
                    guard let attachmentService = attachmentService else { return }
                    cell.attachmentContainerView.emptyStateView.isHidden = error == nil
                    cell.attachmentContainerView.descriptionBackgroundView.isHidden = error != nil
                    if let error = error {
                        cell.attachmentContainerView.activityIndicatorView.stopAnimating()
                        cell.attachmentContainerView.emptyStateView.label.text = error.localizedDescription
                    } else {
                        guard let uploadState = uploadState else { return }
                        switch uploadState {
                        case is MastodonAttachmentService.UploadState.Finish,
                             is MastodonAttachmentService.UploadState.Fail:
                            cell.attachmentContainerView.activityIndicatorView.stopAnimating()
                            cell.attachmentContainerView.emptyStateView.label.text = {
                                if let file = attachmentService.file.value {
                                    switch file {
                                    case .jpeg, .png, .gif:
                                        return L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.photo)
                                    case .other:
                                        return L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.video)
                                    }
                                } else {
                                    return L10n.Scene.Compose.Attachment.attachmentBroken(L10n.Scene.Compose.Attachment.photo)
                                }
                            }()
                        default:
                            break
                        }
                    }
                }
                .store(in: &cell.disposeBag)
                NotificationCenter.default.publisher(
                    for: UITextView.textDidChangeNotification,
                    object: cell.attachmentContainerView.descriptionTextView
                )
                .receive(on: DispatchQueue.main)
                .sink { notification in
                    guard let textField = notification.object as? UITextView else { return }
                    let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                    attachmentService.description.value = text
                }
                .store(in: &cell.disposeBag)
                return cell
            }
        }
    }

}

