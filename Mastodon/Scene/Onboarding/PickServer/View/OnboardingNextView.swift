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
    
    static let buttonHeight: CGFloat = 50
        
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

    let explanationLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .regular))
        label.text = L10n.Scene.ServerPicker.noServerSelectedHint
        return label
    }()

    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    private var isLoading: Bool = false

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
        container.addArrangedSubview(explanationLabel)

        addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 16),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 16),

            nextButton.widthAnchor.constraint(equalTo: container.widthAnchor),
            explanationLabel.widthAnchor.constraint(equalTo: container.widthAnchor),
        ])
        
        NSLayoutConstraint.activate([
            nextButton.heightAnchor.constraint(greaterThanOrEqualToConstant: NavigationActionView.buttonHeight)
        ])
    }

    func showLoading() {
        guard isLoading == false else { return }
        nextButton.isEnabled = false
        isLoading = true
        nextButton.setTitle("", for: .disabled)

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
        nextButton.isEnabled = true
        nextButton.setTitle(L10n.Common.Controls.Actions.next, for: .disabled)
    }
}

