//
//  TimelinePostView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/28.
//

import UIKit
import AVKit

final class TimelinePostView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
    let avatarImageView = UIImageView()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.text = "Alice"
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.text = "@alice"
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredMonospacedFont(withTextStyle: .callout)
        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .left : .right
        label.textColor = .secondaryLabel
        label.text = "1d"
        return label
    }()
    
    let mainContainerStackView = UIStackView()
    
        
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
        // container: [retweet | post]
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
        
        // post container: [user avatar | tweet container]
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

        // tweet container: [user meta container | main container | action toolbar]
        let tweetContainerStackView = UIStackView()
        postContainerStackView.addArrangedSubview(tweetContainerStackView)
        tweetContainerStackView.axis = .vertical
        tweetContainerStackView.spacing = 2
        
        // user meta container: [name | lock | username | date | menu]
        let userMetaContainerStackView = UIStackView()
        tweetContainerStackView.addArrangedSubview(userMetaContainerStackView)
        userMetaContainerStackView.axis = .horizontal
        userMetaContainerStackView.alignment = .center
        userMetaContainerStackView.spacing = 6
        userMetaContainerStackView.addArrangedSubview(nameLabel)
        userMetaContainerStackView.addArrangedSubview(usernameLabel)
        userMetaContainerStackView.addArrangedSubview(dateLabel)
        nameLabel.setContentHuggingPriority(.defaultHigh + 10, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        usernameLabel.setContentHuggingPriority(.defaultHigh + 3, for: .horizontal)
        usernameLabel.setContentCompressionResistancePriority(.defaultHigh - 1, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)

    }
    
}

