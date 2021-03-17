//
//  AttachmentContainerView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import UIKit

final class AttachmentContainerView: UIView {
    
    let attachmentPreviewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.layer.cornerCurve = .continuous
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension AttachmentContainerView {
    
    private func _init() {
        
        attachmentPreviewImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(attachmentPreviewImageView)
        NSLayoutConstraint.activate([
            attachmentPreviewImageView.topAnchor.constraint(equalTo: topAnchor),
            attachmentPreviewImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            attachmentPreviewImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            attachmentPreviewImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
    }
    
}
