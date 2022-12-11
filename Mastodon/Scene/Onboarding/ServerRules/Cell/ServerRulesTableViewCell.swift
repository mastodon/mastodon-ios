//
//  ServerRulesTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-5.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class ServerRulesTableViewCell: UITableViewCell {
    
    static let margin: CGFloat = 23
    
    let indexImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Asset.Colors.Label.primary.color
        return imageView
    }()
    
    let ruleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        label.textColor = Asset.Colors.Label.primary.color
        label.numberOfLines = 0
        return label
    }()
    
    let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Theme.System.separator.color
        return view
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

extension ServerRulesTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        indexImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(indexImageView)
        NSLayoutConstraint.activate([
            indexImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 11),
            indexImageView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: indexImageView.bottomAnchor, constant: ServerRulesTableViewCell.margin),
            indexImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            indexImageView.widthAnchor.constraint(equalToConstant: 32).priority(.required - 1),
            indexImageView.heightAnchor.constraint(equalToConstant: 32).priority(.required - 1),
        ])
        
        ruleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ruleLabel)
        NSLayoutConstraint.activate([
            ruleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 11),
            ruleLabel.leadingAnchor.constraint(equalTo: indexImageView.trailingAnchor, constant: 14),
            ruleLabel.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: ruleLabel.bottomAnchor, constant: 11),
            ruleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: ruleLabel.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.required - 1),
        ])
    }
    
}
