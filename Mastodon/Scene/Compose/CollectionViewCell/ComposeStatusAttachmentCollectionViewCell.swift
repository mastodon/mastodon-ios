//
//  ComposeStatusAttachmentCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import os.log
import UIKit
import Combine
import MastodonUI
import MastodonAsset
import MastodonLocalization

protocol ComposeStatusAttachmentCollectionViewCellDelegate: AnyObject {
    func composeStatusAttachmentCollectionViewCell(_ cell: ComposeStatusAttachmentCollectionViewCell, removeButtonDidPressed button: UIButton)
}

final class ComposeStatusAttachmentCollectionViewCell: UICollectionViewCell {

    let logger = Logger(subsystem: "ComposeStatusAttachmentCollectionViewCell", category: "UI")

    var disposeBag = Set<AnyCancellable>()

    static let verticalMarginHeight: CGFloat = ComposeStatusAttachmentCollectionViewCell.removeButtonSize.height * 0.5
    static let removeButtonSize = CGSize(width: 22, height: 22)
    
    weak var delegate: ComposeStatusAttachmentCollectionViewCellDelegate?
    
//    let attachmentContainerView = AttachmentContainerView()
    let removeButton: UIButton = {
        let button = HighlightDimmableButton()
        button.expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        let image = UIImage(systemName: "minus")!.withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .bold))
        button.tintColor = .white
        button.setImage(image, for: .normal)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.danger.color), for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = ComposeStatusAttachmentCollectionViewCell.removeButtonSize.width * 0.5
        button.layer.borderColor = Asset.Colors.dangerBorder.color.cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
//        attachmentContainerView.activityIndicatorView.startAnimating()
//        attachmentContainerView.previewImageView.af.cancelImageRequest()
//        attachmentContainerView.previewImageView.image = .placeholder(color: .systemFill)
//        delegate = nil
//        disposeBag.removeAll()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    deinit {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
    
}

extension ComposeStatusAttachmentCollectionViewCell {
    
    private func _init() {
        // selectionStyle = .none
        
//        attachmentContainerView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(attachmentContainerView)
//        NSLayoutConstraint.activate([
//            attachmentContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ComposeStatusAttachmentCollectionViewCell.verticalMarginHeight),
//            attachmentContainerView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
//            attachmentContainerView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
//            contentView.bottomAnchor.constraint(equalTo: attachmentContainerView.bottomAnchor, constant: ComposeStatusAttachmentCollectionViewCell.verticalMarginHeight),
//            attachmentContainerView.heightAnchor.constraint(equalToConstant: 205).priority(.defaultHigh),
//        ])
//
//        removeButton.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(removeButton)
//        NSLayoutConstraint.activate([
//            removeButton.centerXAnchor.constraint(equalTo: attachmentContainerView.trailingAnchor),
//            removeButton.centerYAnchor.constraint(equalTo: attachmentContainerView.topAnchor),
//            removeButton.widthAnchor.constraint(equalToConstant: ComposeStatusAttachmentCollectionViewCell.removeButtonSize.width).priority(.defaultHigh),
//            removeButton.heightAnchor.constraint(equalToConstant: ComposeStatusAttachmentCollectionViewCell.removeButtonSize.height).priority(.defaultHigh),
//        ])
//
//        removeButton.addTarget(self, action: #selector(ComposeStatusAttachmentCollectionViewCell.removeButtonDidPressed(_:)), for: .touchUpInside)
    }

}

extension ComposeStatusAttachmentCollectionViewCell {

    @objc private func removeButtonDidPressed(_ sender: UIButton) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.composeStatusAttachmentCollectionViewCell(self, removeButtonDidPressed: sender)
    }

}
