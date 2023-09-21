//
//  ComposeStatusAttachmentCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import UIKit
import Combine
import MastodonUI
import MastodonAsset
import MastodonLocalization

protocol ComposeStatusAttachmentCollectionViewCellDelegate: AnyObject {
    func composeStatusAttachmentCollectionViewCell(_ cell: ComposeStatusAttachmentCollectionViewCell, removeButtonDidPressed button: UIButton)
}

final class ComposeStatusAttachmentCollectionViewCell: UICollectionViewCell {

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
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}

extension ComposeStatusAttachmentCollectionViewCell {

    @objc private func removeButtonDidPressed(_ sender: UIButton) {
        delegate?.composeStatusAttachmentCollectionViewCell(self, removeButtonDidPressed: sender)
    }

}
