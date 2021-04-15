//
//  ComposeRepliedToStatusContentCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import Combine

final class ComposeRepliedToStatusContentCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let statusView = StatusView()
    
    let framePublisher = PassthroughSubject<CGRect, Never>()

    override func prepareForReuse() {
        super.prepareForReuse()
        
        statusView.isStatusTextSensitive = false
        statusView.cleanUpContentWarning()
        disposeBag.removeAll()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        framePublisher.send(bounds)
    }
    
}

extension ComposeRepliedToStatusContentCollectionViewCell {
    
    private func _init() {
        backgroundColor = .clear
        statusView.contentWarningBlurContentImageView.backgroundColor = Asset.Colors.Background.systemBackground.color

        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statusView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 10),
        ])
        
        statusView.actionToolbarContainer.isHidden = true
    }
    
}

