//
//  ComposeStatusAttachmentTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import UIKit

final class ComposeStatusAttachmentTableViewCell: UITableViewCell {
    
    static let verticalMarginHeight: CGFloat = 8
    
    let attachmentContainerView = AttachmentContainerView()
    
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
        attachmentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(attachmentContainerView)
        NSLayoutConstraint.activate([
            attachmentContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ComposeStatusAttachmentTableViewCell.verticalMarginHeight),
            attachmentContainerView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            attachmentContainerView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: attachmentContainerView.bottomAnchor, constant: ComposeStatusAttachmentTableViewCell.verticalMarginHeight),
            attachmentContainerView.heightAnchor.constraint(equalToConstant: 205).priority(.defaultHigh),
        ])
        
        attachmentContainerView.attachmentPreviewImageView.backgroundColor = .systemFill
    }
    
}

