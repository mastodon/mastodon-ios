//
//  ProfileRelationshipActionButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit
import MastodonUI

final class ProfileRelationshipActionButton: RoundedEdgesButton {
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.color = .white
        return activityIndicatorView
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

extension ProfileRelationshipActionButton {
    private func _init() {
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.stopAnimating()
    }
}

extension ProfileRelationshipActionButton {
    func configure(actionOptionSet: ProfileViewModel.RelationshipActionOptionSet) {
        setTitle(actionOptionSet.title, for: .normal)
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        setBackgroundImage(.placeholder(color: actionOptionSet.backgroundColor), for: .normal)
        setBackgroundImage(.placeholder(color: actionOptionSet.backgroundColor.withAlphaComponent(0.5)), for: .highlighted)
        setBackgroundImage(.placeholder(color: actionOptionSet.backgroundColor.withAlphaComponent(0.5)), for: .disabled)
        
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
}

