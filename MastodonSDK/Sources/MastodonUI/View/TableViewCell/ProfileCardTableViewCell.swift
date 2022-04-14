//
//  ProfileCardTableViewCell.swift
//  
//
//  Created by MainasuK on 2022-4-14.
//

import UIKit
import Combine

public final class ProfileCardTableViewCell: UITableViewCell {
    
    public var disposeBag = Set<AnyCancellable>()
    
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
        
        let shadowBackgroundContainer = ShadowBackgroundContainer()
        shadowBackgroundContainer.cornerRadius = 6
        shadowBackgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shadowBackgroundContainer)
        NSLayoutConstraint.activate([
            shadowBackgroundContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            shadowBackgroundContainer.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            shadowBackgroundContainer.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: shadowBackgroundContainer.bottomAnchor, constant: 10),
        ])
        
        profileCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileCardView)
        NSLayoutConstraint.activate([
            profileCardView.topAnchor.constraint(equalTo: shadowBackgroundContainer.topAnchor),
            profileCardView.leadingAnchor.constraint(equalTo: shadowBackgroundContainer.leadingAnchor),
            profileCardView.trailingAnchor.constraint(equalTo: shadowBackgroundContainer.trailingAnchor),
            profileCardView.bottomAnchor.constraint(equalTo: shadowBackgroundContainer.bottomAnchor),
        ])
    }
    
}
