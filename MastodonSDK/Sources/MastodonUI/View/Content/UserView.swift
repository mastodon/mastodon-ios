//
//  UserView.swift
//  
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import Combine
import MetaTextKit

public final class UserView: UIView {
    
    public var disposeBag = Set<AnyCancellable>()
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(userView: self)
        return viewModel
    }()
    
    public let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    // avatar
    public let avatarButton = AvatarButton()
    
    // author name
    public let authorNameLabel = MetaLabel(style: .statusName)
    
    // author username
    public let authorUsernameLabel = MetaLabel(style: .statusUsername)
    
    public func prepareForReuse() {
        disposeBag.removeAll()
        
        // viewModel.objects.removeAll()
        viewModel.authorAvatarImageURL = nil
        
        avatarButton.avatarImageView.cancelTask()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}


extension UserView {
    
    private func _init() {
        // container
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        containerStackView.pinToParent()
        
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.widthAnchor.constraint(equalToConstant: 28).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: 28).priority(.required - 1),
        ])
        avatarButton.setContentHuggingPriority(.defaultLow, for: .vertical)
        avatarButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // label container
        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        containerStackView.addArrangedSubview(labelStackView)
        
        labelStackView.addArrangedSubview(authorNameLabel)
        labelStackView.addArrangedSubview(authorUsernameLabel)
        authorNameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        authorUsernameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        
        avatarButton.isUserInteractionEnabled = false
        authorNameLabel.isUserInteractionEnabled = false
        authorUsernameLabel.isUserInteractionEnabled = false
    }
    
}
