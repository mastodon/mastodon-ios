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
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 28, weight: .bold))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.ServerPicker.title
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()
    
    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "Pick a community based on your interests, region, or a general purpose one. Each community is operated by an entirely independent organization or individual."
        label.adjustsFontForContentSizeCategory = true
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
        selectionStyle = .none
        backgroundColor = Asset.Scene.Onboarding.onboardingBackground.color
        
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 11),
        ])
        
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(subTitleLabel)
    }

}
