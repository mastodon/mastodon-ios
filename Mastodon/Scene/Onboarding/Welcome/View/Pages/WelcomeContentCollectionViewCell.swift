//
//  WelcomeContentPageView.swift
//  Mastodon
//
//  Created by Nathan Mattes on 26.11.22.
//

import UIKit

class WelcomeContentCollectionViewCell: UICollectionViewCell {

    static let identifier = "WelcomeContentCollectionViewCell"
    
    //TODO: Put in ScrollView?
    private let contentStackView: UIStackView
    private let titleView: UILabel
    private let label: UILabel

    override init(frame: CGRect) {
        titleView = UILabel()
        titleView.font = WelcomeViewController.largeTitleFont
        titleView.textColor = WelcomeViewController.largeTitleTextColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        titleView.adjustsFontForContentSizeCategory = true
        titleView.numberOfLines = 0
        
        label = UILabel()
        label.font = WelcomeViewController.subTitleFont
        label.textColor = WelcomeViewController.largeTitleTextColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        
        contentStackView = UIStackView(arrangedSubviews: [titleView, label, UIView()])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.alignment = .leading
        contentStackView.spacing = 8

        super.init(frame: frame)

        addSubview(contentStackView)
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupConstraints() {
        let constraints = [
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 16),
            bottomAnchor.constraint(greaterThanOrEqualTo: contentStackView.bottomAnchor),
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func updateAccessibility() {
        accessibilityLabel = "\(titleView.accessibilityLabel ?? ""), \(label.accessibilityLabel ?? "")"
        isAccessibilityElement = true
    }

    func update(with page: WelcomeContentPage) {
        titleView.attributedText = page.title
        titleView.accessibilityLabel = page.accessibilityLabel
        label.text = page.content
        updateAccessibility()
    }
}
