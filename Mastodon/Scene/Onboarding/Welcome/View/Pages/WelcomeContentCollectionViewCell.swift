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
    private let blurryBackgroundView: UIVisualEffectView

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

        blurryBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        blurryBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        blurryBackgroundView.applyCornerRadius(radius: 8)

        blurryBackgroundView.contentView.addSubview(contentStackView)
        
        super.init(frame: frame)

        addSubview(blurryBackgroundView)
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupConstraints() {
        let constraints = [
            blurryBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            blurryBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: blurryBackgroundView.trailingAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: blurryBackgroundView.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: blurryBackgroundView.contentView.topAnchor, constant: 8),
            contentStackView.leadingAnchor.constraint(equalTo: blurryBackgroundView.contentView.leadingAnchor, constant: 8),
            blurryBackgroundView.contentView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            blurryBackgroundView.contentView.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor),
        ]
        
        NSLayoutConstraint.activate(constraints)
    }

    func update(with page: WelcomeContentPage) {
        titleView.attributedText = page.title
        label.text = page.content
    }
}
