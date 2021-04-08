//
//  ProfileRelationshipActionButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit

final class ProfileRelationshipActionButton: RoundedEdgesButton {
    
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
        // do nothing
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
        
        if let option = actionOptionSet.highPriorityAction(except: .editOptions), option == .blocked {
            isEnabled = false
        } else {
            isEnabled = true
        }
    }
}

