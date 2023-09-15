//
//  HashtagTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import UIKit
import MetaTextKit

final class HashtagTableViewCell: UITableViewCell {

    static let reuseIdentifier = "HashtagTableViewCell"
    
    let primaryLabel = MetaLabel(style: .statusName)
    
    let separatorLine = UIView.separatorLine
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension HashtagTableViewCell {
    
    private func _init() {
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(primaryLabel)
        NSLayoutConstraint.activate([
            primaryLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            primaryLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            primaryLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: primaryLabel.bottomAnchor, constant: 11),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.required - 1),
        ])
        
        primaryLabel.isUserInteractionEnabled = false
    }
    
}
