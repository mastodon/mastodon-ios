//
//  ProfileFriendshipActionButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit

final class ProfileFriendshipActionButton: RoundedEdgesButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileFriendshipActionButton {
    private func _init() {
        configure(state: .follow)
    }
}

extension ProfileFriendshipActionButton {
    enum State {
        case follow
        case following
        case blocked
        case muted
        case edit
        case editing
        
        var title: String {
            switch self {
            case .follow: return L10n.Common.Controls.Firendship.follow
            case .following: return L10n.Common.Controls.Firendship.following
            case .blocked: return L10n.Common.Controls.Firendship.blocked
            case .muted: return L10n.Common.Controls.Firendship.muted
            case .edit: return L10n.Common.Controls.Firendship.editInfo
            case .editing: return L10n.Common.Controls.Actions.done
            }
        }
        
        var backgroundColor: UIColor {
            switch self {
            case .follow: return Asset.Colors.Button.normal.color
            case .following: return Asset.Colors.Button.normal.color
            case .blocked: return Asset.Colors.Background.danger.color
            case .muted: return Asset.Colors.Background.alertYellow.color
            case .edit: return Asset.Colors.Button.normal.color
            case .editing: return Asset.Colors.Button.normal.color
            }
        }
    }
    
    private func configure(state: State) {
        setTitle(state.title, for: .normal)
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        setBackgroundImage(.placeholder(color: state.backgroundColor), for: .normal)
        setBackgroundImage(.placeholder(color: state.backgroundColor.withAlphaComponent(0.5)), for: .highlighted)
        setBackgroundImage(.placeholder(color: state.backgroundColor.withAlphaComponent(0.5)), for: .disabled)
    }
}

