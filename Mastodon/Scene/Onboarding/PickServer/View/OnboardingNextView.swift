//
//  OnboardingNextView.swift
//  Mastodon
//
//  Created by Nathan Mattes on 2022-12-12.
//

import UIKit
import MastodonUI
import MastodonAsset
import MastodonLocalization

final class OnboardingNextView: UIView {
    
    let buttonHeight: CGFloat = 50
        
    private let container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()

    let nextButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 14
        button.backgroundColor = Asset.Colors.Brand.blurple.color
        button.setTitle(L10n.Common.Controls.Actions.next, for: .normal)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 16, weight: .bold))
        return button
    }()

    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    private var isLoading: Bool = false
    var canProceed: Bool = true {
        didSet { updateNextButtonState() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(nextButton)

        addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 16),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 16),

            nextButton.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
        
        NSLayoutConstraint.activate([
            nextButton.heightAnchor.constraint(greaterThanOrEqualToConstant: buttonHeight)
        ])
    }

    func showLoading() {
        guard isLoading == false else { return }
        isLoading = true
        nextButton.setTitle("", for: .disabled)
        updateNextButtonState()

        nextButton.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: nextButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
        ])
        activityIndicator.startAnimating()
    }

    func stopLoading() {
        guard isLoading else { return }
        isLoading = false
        if activityIndicator.superview == nextButton {
            activityIndicator.removeFromSuperview()
        }
        updateNextButtonState()
        nextButton.setTitle(L10n.Common.Controls.Actions.next, for: .disabled)
    }
    
    private func updateNextButtonState() {
        nextButton.isEnabled = canProceed && !isLoading
        nextButton.alpha = nextButton.isEnabled ? 1 : 0.5
    }
}

