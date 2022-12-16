//
//  WelcomeContentPageView.swift
//  Mastodon
//
//  Created by Nathan Mattes on 26.11.22.
//

import UIKit

class WelcomeContentPageView: UIView {
    
    //TODO: Put in ScrollView?
    private let contentStackView: UIStackView
    private let titleView: UILabel
    private let label: UILabel
    
    init(page: WelcomeContentPage) {
        
        titleView = UILabel()
        titleView.font = WelcomeViewController.largeTitleFont
        titleView.textColor = WelcomeViewController.largeTitleTextColor
        titleView.attributedText = page.title
        titleView.adjustsFontForContentSizeCategory = true
        titleView.numberOfLines = 0
        
        label = UILabel()
        label.text = page.content
        label.font = WelcomeViewController.subTitleFont
        label.textColor = WelcomeViewController.largeTitleTextColor
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        
        contentStackView = UIStackView(arrangedSubviews: [titleView, label, UIView()])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.alignment = .leading
        contentStackView.spacing = 8
        
        super.init(frame: .zero)
        
        addSubview(contentStackView)
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupConstraints() {
        let constraints = [
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 16),
            bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}
