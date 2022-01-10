//
//  MastodonRegisterAvatarTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-5.
//

import UIKit
import Combine

final class MastodonRegisterAvatarTableViewCell: UITableViewCell {
    
    static let containerSize = CGSize(width: 88, height: 88)
    
    var disposeBag = Set<AnyCancellable>()
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.masksToBounds = true
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 22
        return view
    }()
    
    let avatarButton: HighlightDimmableButton = {
        let button = HighlightDimmableButton()
        button.backgroundColor = Asset.Theme.Mastodon.secondaryGroupedSystemBackground.color
        button.setImage(Asset.Scene.Onboarding.avatarPlaceholder.image, for: .normal)
        return button
    }()
    
    let editBannerView: UIView = {
        let bannerView = UIView()
        bannerView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        bannerView.isUserInteractionEnabled = false
        
        let label: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.text = L10n.Common.Controls.Actions.edit
            label.font = .systemFont(ofSize: 13, weight: .semibold)
            label.textAlignment = .center
            label.minimumScaleFactor = 0.5
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        bannerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bannerView.topAnchor),
            label.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor),
        ])
        
        return bannerView
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MastodonRegisterAvatarTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 8),
            containerView.widthAnchor.constraint(equalToConstant: MastodonRegisterAvatarTableViewCell.containerSize.width).priority(.required - 1),
            containerView.heightAnchor.constraint(equalToConstant: MastodonRegisterAvatarTableViewCell.containerSize.height).priority(.required - 1),
        ])
        
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        editBannerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(editBannerView)
        NSLayoutConstraint.activate([
            editBannerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            editBannerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            editBannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            editBannerView.heightAnchor.constraint(equalToConstant: 22),
        ])
    }
    
}
