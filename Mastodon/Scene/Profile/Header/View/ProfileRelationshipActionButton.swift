//
//  ProfileRelationshipActionButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit

final class ProfileRelationshipActionButton: RoundedEdgesButton {
    
    let actvityIndicatorView: UIActivityIndicatorView = {
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
        actvityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actvityIndicatorView)
        NSLayoutConstraint.activate([
            actvityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            actvityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        actvityIndicatorView.hidesWhenStopped = true
        actvityIndicatorView.stopAnimating()
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
        
        actvityIndicatorView.stopAnimating()
        
        if let option = actionOptionSet.highPriorityAction(except: .editOptions), option == .blocked || option == .suspended {
            isEnabled = false
        } else if actionOptionSet.contains(.updating) {
            isEnabled = false
            actvityIndicatorView.startAnimating()
        } else {
            isEnabled = true
        }
    }
}

