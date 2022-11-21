//
//  ProfileCardTableViewCell.swift
//  
//
//  Created by MainasuK on 2022-4-14.
//

import os.log
import UIKit
import Combine

public protocol ProfileCardTableViewCellDelegate: AnyObject {
    func profileCardTableViewCell(_ cell: ProfileCardTableViewCell, profileCardView: ProfileCardView, relationshipButtonDidPressed button: ProfileRelationshipActionButton)
    func profileCardTableViewCell(_ cell: ProfileCardTableViewCell, profileCardView: ProfileCardView, familiarFollowersDashboardViewDidPressed view: FamiliarFollowersDashboardView)
}

public final class ProfileCardTableViewCell: UITableViewCell {
    
    let logger = Logger(subsystem: "ProfileCardTableViewCell", category: "Cell")
    
    public weak var delegate: ProfileCardTableViewCellDelegate?
    public var disposeBag = Set<AnyCancellable>()
    
    public let shadowBackgroundContainer = ShadowBackgroundContainer()
    
    public let profileCardView: ProfileCardView = {
        let profileCardView = ProfileCardView()
        profileCardView.layer.masksToBounds = true
        profileCardView.layer.cornerRadius = 6
        profileCardView.layer.cornerCurve = .continuous
        return profileCardView
    }()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        profileCardView.prepareForReuse()
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileCardTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        shadowBackgroundContainer.cornerRadius = 6
        shadowBackgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shadowBackgroundContainer)
        NSLayoutConstraint.activate([
            shadowBackgroundContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).priority(.required - 1),
            shadowBackgroundContainer.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            shadowBackgroundContainer.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: shadowBackgroundContainer.bottomAnchor, constant: 10).priority(.required - 1),
        ])
        
        profileCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileCardView)
        profileCardView.pinTo(to: shadowBackgroundContainer)
        
        profileCardView.delegate = self
        
        profileCardView.isAccessibilityElement = true
        accessibilityElements = [
            profileCardView,
            profileCardView.relationshipActionButton
        ]
    }
    
}

// MARK: - ProfileCardViewDelegate
extension ProfileCardTableViewCell: ProfileCardViewDelegate {
    
    public func profileCardView(_ profileCardView: ProfileCardView, relationshipButtonDidPressed button: ProfileRelationshipActionButton) {
        delegate?.profileCardTableViewCell(self, profileCardView: profileCardView, relationshipButtonDidPressed: button)
    }
    
    public func profileCardView(_ profileCardView: ProfileCardView, familiarFollowersDashboardViewDidPressed view: FamiliarFollowersDashboardView) {
        delegate?.profileCardTableViewCell(self, profileCardView: profileCardView, familiarFollowersDashboardViewDidPressed: view)
    }
    
}
