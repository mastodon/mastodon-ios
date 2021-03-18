//
//  ComposeStatusAttachmentTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import os.log
import UIKit
import Combine

protocol ComposeStatusAttachmentTableViewCellDelegate: class {
    func composeStatusAttachmentTableViewCell(_ cell: ComposeStatusAttachmentTableViewCell, removeButtonDidPressed button: UIButton)
}

final class ComposeStatusAttachmentTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()

    static let verticalMarginHeight: CGFloat = ComposeStatusAttachmentTableViewCell.removeButtonSize.height * 0.5
    static let removeButtonSize = CGSize(width: 22, height: 22)
    
    weak var delegate: ComposeStatusAttachmentTableViewCellDelegate?
    
    let attachmentContainerView = AttachmentContainerView()
    let removeButton: UIButton = {
        let button = HighlightDimmableButton()
        button.expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        let image = UIImage(systemName: "minus")!.withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .bold))
        button.tintColor = .white
        button.setImage(image, for: .normal)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.Background.danger.color), for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = ComposeStatusAttachmentTableViewCell.removeButtonSize.width * 0.5
        button.layer.borderColor = Asset.Colors.Background.dangerBorder.color.cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        attachmentContainerView.activityIndicatorView.startAnimating()
        delegate = nil
    }
    
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
        selectionStyle = .none
        
        attachmentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(attachmentContainerView)
        NSLayoutConstraint.activate([
            attachmentContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ComposeStatusAttachmentTableViewCell.verticalMarginHeight),
            attachmentContainerView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            attachmentContainerView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: attachmentContainerView.bottomAnchor, constant: ComposeStatusAttachmentTableViewCell.verticalMarginHeight),
            attachmentContainerView.heightAnchor.constraint(equalToConstant: 205).priority(.defaultHigh),
        ])
        
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(removeButton)
        NSLayoutConstraint.activate([
            removeButton.centerXAnchor.constraint(equalTo: attachmentContainerView.trailingAnchor),
            removeButton.centerYAnchor.constraint(equalTo: attachmentContainerView.topAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: ComposeStatusAttachmentTableViewCell.removeButtonSize.width).priority(.defaultHigh),
            removeButton.heightAnchor.constraint(equalToConstant: ComposeStatusAttachmentTableViewCell.removeButtonSize.height).priority(.defaultHigh),
        ])
        
        removeButton.addTarget(self, action: #selector(ComposeStatusAttachmentTableViewCell.removeButtonDidPressed(_:)), for: .touchUpInside)
    }
    
}


extension ComposeStatusAttachmentTableViewCell {

    @objc private func removeButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.composeStatusAttachmentTableViewCell(self, removeButtonDidPressed: sender)
    }

}
