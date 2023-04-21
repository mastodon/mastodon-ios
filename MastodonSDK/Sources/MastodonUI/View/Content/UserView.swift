//
//  UserView.swift
//  
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import Combine
import MetaTextKit
import MastodonAsset
import os

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
    
    public let authorFollowersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabel
        return label
    }()
    
    public let authorVerifiedLabel: MetaLabel = {
        let label = MetaLabel(style: .profileFieldValue)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular)),
            .foregroundColor: UIColor.secondaryLabel
        ]
        label.linkAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold)),
            .foregroundColor: Asset.Colors.brand.color
        ]
        label.isUserInteractionEnabled = false
        return label
    }()
    
    public let authorVerifiedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let verifiedStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    
    private let verifiedStackCenterSpacerView: UILabel = {
        let label = UILabel()
        label.text = " · "
        label.textColor = .secondaryLabel
        return label
    }()
    
    public func setFollowButtonEnabled(_ enabled: Bool) {
        switch enabled {
        case true:
            verifiedStackView.axis = .vertical
            verifiedStackView.alignment = .leading
            verifiedStackCenterSpacerView.isHidden = true
        case false:
            verifiedStackView.axis = .horizontal
            verifiedStackView.alignment = .leading
            verifiedStackCenterSpacerView.isHidden = false
        }
    }
        
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
        
        let nameStackView = UIStackView()
        nameStackView.axis = .horizontal
        
        let nameSpacer = UIView()
        nameSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        nameStackView.addArrangedSubview(authorNameLabel)
        nameStackView.addArrangedSubview(authorUsernameLabel)
        nameStackView.addArrangedSubview(nameSpacer)
        
        authorNameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        authorNameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        authorUsernameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        authorUsernameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        labelStackView.addArrangedSubview(nameStackView)
                
        let verifiedSpacerView = UIView()
        let verifiedStackTrailingSpacerView = UIView()
        
        verifiedStackTrailingSpacerView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        let verifiedContainerStack = UIStackView()
        verifiedContainerStack.axis = .horizontal
        verifiedContainerStack.alignment = .center

        NSLayoutConstraint.activate([
            authorVerifiedImageView.widthAnchor.constraint(equalToConstant: 15),
            verifiedSpacerView.widthAnchor.constraint(equalToConstant: 2)
        ])
        
        verifiedContainerStack.addArrangedSubview(authorVerifiedImageView)
        verifiedContainerStack.addArrangedSubview(verifiedSpacerView)
        verifiedContainerStack.addArrangedSubview(authorVerifiedLabel)
        
        verifiedStackView.addArrangedSubview(authorFollowersLabel)
        verifiedStackView.addArrangedSubview(verifiedStackCenterSpacerView)
        verifiedStackView.addArrangedSubview(verifiedContainerStack)
        verifiedStackView.addArrangedSubview(verifiedStackTrailingSpacerView)
    
        labelStackView.addArrangedSubview(verifiedStackView)

        avatarButton.isUserInteractionEnabled = false
        authorNameLabel.isUserInteractionEnabled = false
        authorUsernameLabel.isUserInteractionEnabled = false

        isAccessibilityElement = true
    }
    
}
