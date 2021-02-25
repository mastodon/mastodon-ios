//
//  PickServerTitleCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit

final class PickServerTitleCell: UITableViewCell {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: UIFont.boldSystemFont(ofSize: 34))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.ServerPicker.title
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
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

extension PickServerTitleCell {
    
    private func _init() {
        self.selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}
