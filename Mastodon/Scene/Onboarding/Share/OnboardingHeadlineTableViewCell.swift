//
//  OnboardingHeadlineTableViewCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class OnboardingHeadlineTableViewCell: UITableViewCell {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = MastodonPickServerViewController.largeTitleFont
        label.textColor = MastodonPickServerViewController.largeTitleTextColor
        label.text = L10n.Scene.ServerPicker.title
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()
    
    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = MastodonPickServerViewController.subTitleFont
        label.textColor = MastodonPickServerViewController.subTitleTextColor
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

extension OnboardingHeadlineTableViewCell {
    
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
