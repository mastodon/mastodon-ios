//
//  MastodonRegisterPasswordHintTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-7.
//

import UIKit

final class MastodonRegisterPasswordHintTableViewCell: UITableViewCell {
    
    let passwordRuleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = L10n.Scene.Register.Input.Password.hint
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

extension MastodonRegisterPasswordHintTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        passwordRuleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(passwordRuleLabel)
        NSLayoutConstraint.activate([
            passwordRuleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            passwordRuleLabel.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            passwordRuleLabel.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            passwordRuleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
}
