//
//  NavigationActionView.swift
//  Mastodon
//
//  Created by MainasuK on 2021-12-31.
//

import UIKit
import MastodonUI

final class NavigationActionView: UIView {
    
    static let buttonHeight: CGFloat = 50
    
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
        button.setTitle(L10n.Common.Controls.Actions.back, for: .normal)
        return button
    }()
    
    let nextButtonShadowContainer = ShadowBackgroundContainer()
    let nextButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.action = .next
        button.setTitle(L10n.Common.Controls.Actions.next, for: .normal)
        return button
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
            backButtonShadowContainer.heightAnchor.constraint(equalToConstant: NavigationActionView.buttonHeight).priority(.required - 1),
            nextButtonShadowContainer.heightAnchor.constraint(equalToConstant: NavigationActionView.buttonHeight).priority(.required - 1),
            nextButtonShadowContainer.widthAnchor.constraint(equalTo: backButtonShadowContainer.widthAnchor, multiplier: 2).priority(.required - 1),
        ])
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButtonShadowContainer.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: backButtonShadowContainer.topAnchor),
            backButton.leadingAnchor.constraint(equalTo: backButtonShadowContainer.leadingAnchor),
            backButton.trailingAnchor.constraint(equalTo: backButtonShadowContainer.trailingAnchor),
            backButton.bottomAnchor.constraint(equalTo: backButtonShadowContainer.bottomAnchor),
        ])
        
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButtonShadowContainer.addSubview(nextButton)
        NSLayoutConstraint.activate([
            nextButton.topAnchor.constraint(equalTo: nextButtonShadowContainer.topAnchor),
            nextButton.leadingAnchor.constraint(equalTo: nextButtonShadowContainer.leadingAnchor),
            nextButton.trailingAnchor.constraint(equalTo: nextButtonShadowContainer.trailingAnchor),
            nextButton.bottomAnchor.constraint(equalTo: nextButtonShadowContainer.bottomAnchor),
        ])
    }
    
}
