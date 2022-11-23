//
//  HashtagTimelineHeaderView.swift
//  Mastodon
//
//  Created by Marcus Kida on 22.11.22.
//

import UIKit
import MastodonSDK
import MastodonUI
import MastodonAsset

fileprivate extension CGFloat {
    static let padding: CGFloat = 16
    static let descriptionLabelSpacing: CGFloat = 12
}

final class HashtagTimelineHeaderView: UIView {
    let titleLabel = UILabel()

    let postCountLabel = UILabel()
    let participantsLabel = UILabel()
    let postsTodayLabel = UILabel()

    let postCountDescLabel = UILabel()
    let participantsDescLabel = UILabel()
    let postsTodayDescLabel = UILabel()
    
    private var widthConstraint: NSLayoutConstraint!
    
    let followButton: UIButton = {
        let button = RoundedEdgesButton(type: .custom)
        button.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 5, right: 16)     // set 28pt height
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        return button
    }()
    
    init() {
        super.init(frame: .zero)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

private extension HashtagTimelineHeaderView {
    func setupLayout() {
        [titleLabel, postCountLabel, participantsLabel, postsTodayLabel, postCountDescLabel, participantsDescLabel, postsTodayDescLabel, followButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        // hashtag name / title
        titleLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))
        
        [postCountLabel, participantsLabel, postsTodayLabel].forEach {
            $0.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: .systemFont(ofSize: 20, weight: .bold))
            $0.text = "999"
        }
        
        [postCountDescLabel, participantsDescLabel, postsTodayDescLabel].forEach {
            $0.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .regular))
        }
        
        postCountDescLabel.text = "posts"
        participantsDescLabel.text = "participants"
        postsTodayDescLabel.text = "posts today"
                
        widthConstraint = widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            widthConstraint,
            
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: .padding),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .padding),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CGFloat.padding),
            
            postCountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding),
            postCountLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            postCountDescLabel.leadingAnchor.constraint(equalTo: postCountLabel.leadingAnchor),
            
            participantsDescLabel.leadingAnchor.constraint(equalTo: postCountDescLabel.trailingAnchor, constant: .descriptionLabelSpacing),
            participantsLabel.centerXAnchor.constraint(equalTo: participantsDescLabel.centerXAnchor),
            participantsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding),
            
            postsTodayDescLabel.leadingAnchor.constraint(equalTo: participantsDescLabel.trailingAnchor, constant: .descriptionLabelSpacing),
            postsTodayLabel.centerXAnchor.constraint(equalTo: postsTodayDescLabel.centerXAnchor),
            postsTodayLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding),
            
            postCountDescLabel.topAnchor.constraint(equalTo: postCountLabel.bottomAnchor),
            participantsDescLabel.topAnchor.constraint(equalTo: participantsLabel.bottomAnchor),
            postsTodayDescLabel.topAnchor.constraint(equalTo: postsTodayLabel.bottomAnchor),
            
            postCountDescLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -CGFloat.padding),
            participantsDescLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -CGFloat.padding),
            postsTodayDescLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -CGFloat.padding),
        
            followButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CGFloat.padding),
            followButton.bottomAnchor.constraint(equalTo: postsTodayDescLabel.bottomAnchor),
            followButton.topAnchor.constraint(equalTo: postsTodayLabel.topAnchor)
        ])
    }
}

extension HashtagTimelineHeaderView {
    func update(_ entity: Mastodon.Entity.Tag) {
        titleLabel.text = "#\(entity.name)"
        followButton.setTitle(entity.following == true ? "Unfollow" : "Follow", for: .normal)

        followButton.backgroundColor = entity.following == true ? Asset.Colors.Button.tagUnfollow.color : Asset.Colors.Button.tagFollow.color
        followButton.setTitleColor(
            entity.following == true ? Asset.Colors.Button.tagFollow.color : Asset.Colors.Button.tagUnfollow.color,
            for: .normal
        )

        if let history = entity.history {
            postCountLabel.text = String(
                history.reduce(0) { res, acc in
                    res + (Int(acc.uses) ?? 0)
                }
            )
            
            participantsLabel.text = String(
                history.reduce(0) { res, acc in
                    res + (Int(acc.accounts) ?? 0)
                }
            )
            
            postsTodayLabel.text = history.first?.uses
        }
    }
    
    func updateWidthConstraint(_ constant: CGFloat) {
        widthConstraint.constant = constant
    }
}
