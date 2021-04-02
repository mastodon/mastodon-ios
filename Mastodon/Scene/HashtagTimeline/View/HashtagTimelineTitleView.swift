//
//  HashtagTimelineTitleView.swift
//  Mastodon
//
//  Created by BradGao on 2021/4/1.
//

import UIKit

final class HashtagTimelineTitleView: UIView {
    
    let containerView = UIStackView()
    
    let imageView = UIImageView()
    let button = RoundedEdgesButton()
    let label = UILabel()
    
    // input
    private var blockingState: HomeTimelineNavigationBarTitleViewModel.State?
    weak var delegate: HomeTimelineNavigationBarTitleViewDelegate?
    
    // output
    private(set) var state: HomeTimelineNavigationBarTitleViewModel.State = .logoImage
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension HomeTimelineNavigationBarTitleView {
    private func _init() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        containerView.addArrangedSubview(imageView)
        button.translatesAutoresizingMaskIntoConstraints = false
        containerView.addArrangedSubview(button)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 24).priority(.defaultHigh)
        ])
        containerView.addArrangedSubview(label)
        
        configure(state: .logoImage)
        button.addTarget(self, action: #selector(HomeTimelineNavigationBarTitleView.buttonDidPressed(_:)), for: .touchUpInside)
    }
}
