//
//  TimelinePostView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/28.
//

import UIKit
import AVKit
import ActiveLabel

final class TimelinePostView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = avatarImageViewSize.width/2
        imageView.layer.cornerCurve = .continuous
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let visibilityImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.TootTimeline.global.image.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = Asset.Colors.tootGray.color
        return imageView
    }()
    
    let lockImageView: UIImageView = {
        let imageview = UIImageView(image: Asset.TootTimeline.textlock.image.withRenderingMode(.alwaysTemplate))
        imageview.tintColor = Asset.Colors.tootGray.color
        imageview.isHidden = true
        return imageview
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Roboto-Medium", size: 14)
        label.textColor = Asset.Colors.tootWhite.color
        
        label.text = "Alice"
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.tootGray.color
        label.font = UIFont(name: "Roboto-Regular", size: 14)
        label.text = "@alice"
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Roboto-Regular", size: 14)
        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .left : .right
        label.textColor = Asset.Colors.tootGray.color
        label.text = "1d"
        return label
    }()
    
    let actionToolbarContainer: ActionToolbarContainer = {
        let actionToolbarContainer = ActionToolbarContainer()
        actionToolbarContainer.configure(for: .inline)
        return actionToolbarContainer
    }()
    
    let mainContainerStackView = UIStackView()
    
    let activeTextLabel = ActiveLabel(style: .default)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension TimelinePostView {
    
    func _init() {
        // container: [retoot | post]
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
        //containerStackView.alignment = .top
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        // post container: [user avatar | toot container]
        let postContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(postContainerStackView)
        postContainerStackView.axis = .horizontal
        postContainerStackView.spacing = 10
        postContainerStackView.alignment = .top
        
        // user avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        postContainerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: TimelinePostView.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: TimelinePostView.avatarImageViewSize.height).priority(.required - 1),
        ])

        // toot container: [user meta container | main container | action toolbar]
        let tootContainerStackView = UIStackView()
        postContainerStackView.addArrangedSubview(tootContainerStackView)
        tootContainerStackView.axis = .vertical
        tootContainerStackView.spacing = 2
        
        // user meta container: [name | lock | username | visiablity | date ]
        let userMetaContainerStackView = UIStackView()
        tootContainerStackView.addArrangedSubview(userMetaContainerStackView)
        userMetaContainerStackView.axis = .horizontal
        userMetaContainerStackView.alignment = .center
        userMetaContainerStackView.spacing = 6
        userMetaContainerStackView.addArrangedSubview(nameLabel)
        userMetaContainerStackView.addArrangedSubview(lockImageView)
        userMetaContainerStackView.addArrangedSubview(usernameLabel)
        userMetaContainerStackView.addArrangedSubview(visibilityImageView)
        userMetaContainerStackView.addArrangedSubview(dateLabel)
        nameLabel.setContentHuggingPriority(.defaultHigh + 10, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        lockImageView.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        lockImageView.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        usernameLabel.setContentHuggingPriority(.defaultHigh - 3, for: .horizontal)
        usernameLabel.setContentCompressionResistancePriority(.defaultHigh - 1, for: .horizontal)
        visibilityImageView.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        visibilityImageView.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
        
        // main container: [text | image / video | quote | geo]
        tootContainerStackView.addArrangedSubview(mainContainerStackView)
        mainContainerStackView.axis = .vertical
        mainContainerStackView.spacing = 8
        activeTextLabel.translatesAutoresizingMaskIntoConstraints = false
        mainContainerStackView.addArrangedSubview(activeTextLabel)

        activeTextLabel.setContentCompressionResistancePriority(.required - 2, for: .vertical)
        
        // action toolbar
        actionToolbarContainer.translatesAutoresizingMaskIntoConstraints = false
        tootContainerStackView.addArrangedSubview(actionToolbarContainer)
        actionToolbarContainer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

    }
    
}

