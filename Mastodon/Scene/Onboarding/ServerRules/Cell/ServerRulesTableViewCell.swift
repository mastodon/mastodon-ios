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
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        label.textColor = Asset.Colors.Label.primary.color
        label.numberOfLines = 0
        return label
    }()
    
    let separalerLine: UIView = {
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
            indexImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: ServerRulesTableViewCell.margin),
            indexImageView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: indexImageView.bottomAnchor, constant: ServerRulesTableViewCell.margin),
            indexImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            indexImageView.widthAnchor.constraint(equalToConstant: 32).priority(.required - 1),
            indexImageView.heightAnchor.constraint(equalToConstant: 32).priority(.required - 1),
        ])
        
        ruleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ruleLabel)
        NSLayoutConstraint.activate([
            ruleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: ServerRulesTableViewCell.margin),
            ruleLabel.leadingAnchor.constraint(equalTo: indexImageView.trailingAnchor, constant: 16),
            ruleLabel.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: ruleLabel.bottomAnchor, constant: ServerRulesTableViewCell.margin),
            ruleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        separalerLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separalerLine)
        NSLayoutConstraint.activate([
            separalerLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            separalerLine.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            separalerLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separalerLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.required - 1),
        ])
    }
    
}
