//
//  ProfileRelationshipActionButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit
import MastodonAsset
import MastodonLocalization

public final class ProfileRelationshipActionButton: RoundedEdgesButton {
    
    public let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.color = Asset.Colors.Label.primaryReverse.color
        return activityIndicatorView
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileRelationshipActionButton {
    private func _init() {
        cornerRadius = 10
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.stopAnimating()
        
        configureAppearance()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        configureAppearance()
    }
}

extension ProfileRelationshipActionButton {
    public func configure(actionOptionSet: RelationshipActionOptionSet) {
        setTitle(actionOptionSet.title, for: .normal)
        
        configureAppearance()
        
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        
        activityIndicatorView.stopAnimating()
        
        if let option = actionOptionSet.highPriorityAction(except: .editOptions), option == .blocked || option == .suspended {
            isEnabled = false
        } else if actionOptionSet.contains(.updating) {
            isEnabled = false
            activityIndicatorView.startAnimating()
        } else {
            isEnabled = true
        }
    }
    
    private func configureAppearance() {
        setTitleColor(Asset.Colors.Label.primaryReverse.color, for: .normal)
        setTitleColor(Asset.Colors.Label.primaryReverse.color.withAlphaComponent(0.5), for: .highlighted)
        switch traitCollection.userInterfaceStyle {
        case .dark:
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundDark.color), for: .normal)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedDark.color), for: .highlighted)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedDark.color), for: .disabled)
        default:
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundLight.color), for: .normal)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedLight.color), for: .highlighted)
            setBackgroundImage(.placeholder(color: Asset.Scene.Profile.RelationshipButton.backgroundHighlightedLight.color), for: .disabled)
        }
    }
}
