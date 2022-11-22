//
//  NavigationActionView.swift
//  Mastodon
//
//  Created by MainasuK on 2021-12-31.
//

import UIKit
import MastodonUI
import MastodonAsset
import MastodonLocalization

final class NavigationActionView: UIView {
    
    static let buttonHeight: CGFloat = 50
    static let minimumBackButtonWidth: CGFloat = 100
    
    private var observations = Set<NSKeyValueObservation>()
    
    let buttonContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 18
        return stackView
    }()
    
    let backButtonShadowContainer = ShadowBackgroundContainer()
    let backButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.action = .back
        button.contentEdgeInsets = WelcomeViewController.actionButtonPadding
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitle(L10n.Common.Controls.Actions.back, for: .normal)
        return button
    }()
    
    let nextButtonShadowContainer = ShadowBackgroundContainer()
    let nextButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.action = .next
        button.contentEdgeInsets = WelcomeViewController.actionButtonPadding
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitle(L10n.Common.Controls.Actions.next, for: .normal)
        return button
    }()
    
    var hidesBackButton: Bool = false {
        didSet { backButtonShadowContainer.isHidden = hidesBackButton }
    }
    
    var hidesNextButton: Bool = false {
        didSet { nextButtonShadowContainer.isHidden = hidesNextButton }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension NavigationActionView {
    
    private func _init() {
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.preservesSuperviewLayoutMargins = true
        addSubview(buttonContainer)
        NSLayoutConstraint.activate([
            buttonContainer.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            buttonContainer.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: 8),
        ])
        
        backButtonShadowContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addArrangedSubview(backButtonShadowContainer)
        nextButtonShadowContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addArrangedSubview(nextButtonShadowContainer)
        NSLayoutConstraint.activate([
            backButtonShadowContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: NavigationActionView.buttonHeight).priority(.required - 1),
            nextButtonShadowContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: NavigationActionView.buttonHeight).priority(.required - 1),
        ])
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButtonShadowContainer.addSubview(backButton)
        backButton.pinToParent()
        
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButtonShadowContainer.addSubview(nextButton)        
        nextButton.pinToParent()

        // We want the back button to be as small as possible, allowing the next button to take up
        // any remaining space. .defaultLow is "the priority level at which a button hugs its
        // contents horizontally". Setting this on backButton allows nextButton to eat up remaining
        // space. Note that we have to set this on the backButton, not the container, because it's
        // backButton's size that determines the compression amount.
        backButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // Ensure that the back button has a reasonable minimum tap area.
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(greaterThanOrEqualToConstant: NavigationActionView.minimumBackButtonWidth).priority(.defaultLow - 1)
        ])
    }
    
}
