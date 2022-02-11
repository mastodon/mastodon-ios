//
//  TimelineFooterTableViewCell.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class TimelineFooterTableViewCell: UITableViewCell {
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "info"
        label.numberOfLines = 0
        return label
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

extension TimelineFooterTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 68).priority(.required - 1), // same height to bottom loader
        ])
    }
    
}
