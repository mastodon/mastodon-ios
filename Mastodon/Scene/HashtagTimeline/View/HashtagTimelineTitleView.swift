//
//  HashtagTimelineTitleView.swift
//  Mastodon
//
//  Created by BradGao on 2021/4/1.
//

import UIKit

final class HashtagTimelineNavigationBarTitleView: UIView {
    
    let containerView = UIStackView()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = Asset.Colors.Label.primary.color
        label.textAlignment = .center
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = Asset.Colors.Label.secondary.color
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension HashtagTimelineNavigationBarTitleView {
    private func _init() {
        containerView.axis = .vertical
        containerView.alignment = .center
        containerView.distribution = .fill
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        containerView.addArrangedSubview(titleLabel)
        containerView.addArrangedSubview(subtitleLabel)
    }
    
    func updateTitle(hashtag: String, peopleNumber: String?) {
        titleLabel.text = "#\(hashtag)"
        if let peopleNumebr = peopleNumber {
            subtitleLabel.text = L10n.Scene.Hashtag.prompt(peopleNumebr)
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.text = nil
            subtitleLabel.isHidden = true
        }
    }
}
