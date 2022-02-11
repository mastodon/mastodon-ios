//
//  PrimaryActionButton.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import UIKit
import MastodonAsset
import MastodonLocalization

class PrimaryActionButton: UIButton {
    
    private var originalButtonTitle: String?

    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    var adjustsBackgroundImageWhenUserInterfaceStyleChanges = true
    var action: Action = .next {
        didSet {
            setupAppearance(action: action)
        }
    }
    var isLoading: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension PrimaryActionButton {

    public enum Action {
        case back
        case next
    }
    
}

extension PrimaryActionButton {
    
    private func _init() {
        titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        setTitleColor(.white, for: .normal)
        setupAppearance(action: action)
        applyCornerRadius(radius: 10)
    }

    func setupAppearance(action: Action) {
        switch action {
        case .back:
            setTitleColor(Asset.Colors.Label.primary.color, for: .normal)
            setBackgroundImage(UIImage.placeholder(color: Asset.Scene.Onboarding.navigationBackButtonBackground.color), for: .normal)
            setBackgroundImage(UIImage.placeholder(color: Asset.Scene.Onboarding.navigationBackButtonBackgroundHighlighted.color), for: .highlighted)
            setBackgroundImage(UIImage.placeholder(color: Asset.Colors.disabled.color), for: .disabled)
        case .next:
            setTitleColor(Asset.Colors.Label.primaryReverse.color, for: .normal)
            setBackgroundImage(UIImage.placeholder(color: Asset.Scene.Onboarding.navigationNextButtonBackground.color), for: .normal)
            setBackgroundImage(UIImage.placeholder(color: Asset.Scene.Onboarding.navigationNextButtonBackgroundHighlighted.color), for: .highlighted)
            setBackgroundImage(UIImage.placeholder(color: Asset.Colors.disabled.color), for: .disabled)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if adjustsBackgroundImageWhenUserInterfaceStyleChanges {
            setupAppearance(action: action)
        }
    }
    
    func showLoading() {
        guard !isLoading else { return }
        isEnabled = false
        isLoading = true
        originalButtonTitle = title(for: .disabled)
        self.setTitle("", for: .disabled)
        
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
        activityIndicator.startAnimating()
    }
    
    func stopLoading() {
        guard isLoading else { return }
        isLoading = false
        if activityIndicator.superview == self {
            activityIndicator.removeFromSuperview()
        }
        isEnabled = true
        self.setTitle(originalButtonTitle, for: .disabled)
    }
    
}
