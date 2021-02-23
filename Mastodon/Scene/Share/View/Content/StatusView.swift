//
//  StatusView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/28.
//

import UIKit
import AVKit
import ActiveLabel
import AlamofireImage

final class StatusView: UIView {
    
    static let avatarImageSize = CGSize(width: 42, height: 42)
    static let avatarImageCornerRadius: CGFloat = 4
    
    let headerContainerStackView = UIStackView()
    
    let headerIconLabel: UILabel = {
        let label = UILabel()
        let attributedString = NSMutableAttributedString()
        let imageTextAttachment = NSTextAttachment()
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let configuration = UIImage.SymbolConfiguration(font: font)
        imageTextAttachment.image = UIImage(systemName: "arrow.2.squarepath", withConfiguration: configuration)?.withTintColor(Asset.Colors.Label.secondary.color)
        let imageAttribute = NSAttributedString(attachment: imageTextAttachment)
        attributedString.append(imageAttribute)
        label.attributedText = attributedString
        return label
    }()
    
    let headerInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .medium))
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "Bob boosted"
        return label
    }()
    
    let avatarView = UIView()
    let avatarButton: UIButton = {
        let button = HighlightDimmableButton(type: .custom)
        let placeholderImage = UIImage.placeholder(size: avatarImageSize, color: .systemFill)
            .af.imageRounded(withCornerRadius: StatusView.avatarImageCornerRadius, divideRadiusByImageScale: true)
        button.setImage(placeholderImage, for: .normal)
        return button
    }()
    
    let visibilityImageView: UIImageView = {
        let imageView = UIImageView(image: Asset.TootTimeline.global.image.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = Asset.Colors.Label.secondary.color
        return imageView
    }()
    
    let lockImageView: UIImageView = {
        let imageview = UIImageView(image: Asset.TootTimeline.textlock.image.withRenderingMode(.alwaysTemplate))
        imageview.tintColor = Asset.Colors.Label.secondary.color
        imageview.isHidden = true
        return imageview
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "Alice"
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "@alice"
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "1d"
        return label
    }()
    
    let statusContainerStackView = UIStackView()

    let actionToolbarContainer: ActionToolbarContainer = {
        let actionToolbarContainer = ActionToolbarContainer()
        actionToolbarContainer.configure(for: .inline)
        return actionToolbarContainer
    }()
    
    
    let activeTextLabel = ActiveLabel(style: .default)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension StatusView {
    
    func _init() {
        // container: [retoot | author | status | action toolbar]
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 10
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        // header container: [icon | info]
        containerStackView.addArrangedSubview(headerContainerStackView)
        headerContainerStackView.spacing = 4
        headerContainerStackView.addArrangedSubview(headerIconLabel)
        headerContainerStackView.addArrangedSubview(headerInfoLabel)
        headerIconLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        // author container: [avatar | author meta container]
        let authorContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(authorContainerStackView)
        authorContainerStackView.axis = .horizontal
        authorContainerStackView.spacing = 5

        // avatar
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        authorContainerStackView.addArrangedSubview(avatarView)
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: StatusView.avatarImageSize.width).priority(.required - 1),
            avatarView.heightAnchor.constraint(equalToConstant: StatusView.avatarImageSize.height).priority(.required - 1),
        ])
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
        ])
        
        // author meta container: [title container | subtitle container]
        let authorMetaContainerStackView = UIStackView()
        authorContainerStackView.addArrangedSubview(authorMetaContainerStackView)
        authorMetaContainerStackView.axis = .vertical
        authorMetaContainerStackView.spacing = 4
        
        // title container: [display name | "·" | date]
        let titleContainerStackView = UIStackView()
        authorMetaContainerStackView.addArrangedSubview(titleContainerStackView)
        titleContainerStackView.axis = .horizontal
        titleContainerStackView.spacing = 4
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainerStackView.addArrangedSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.heightAnchor.constraint(equalToConstant: 22).priority(.defaultHigh),
        ])
        titleContainerStackView.alignment = .firstBaseline
        let dotLabel: UILabel = {
            let label = UILabel()
            label.textColor = Asset.Colors.Label.secondary.color
            label.font = .systemFont(ofSize: 17)
            label.text = "·"
            return label
        }()
        titleContainerStackView.addArrangedSubview(dotLabel)
        titleContainerStackView.addArrangedSubview(dateLabel)
        nameLabel.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        dotLabel.setContentHuggingPriority(.defaultHigh + 2, for: .horizontal)
        dotLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        // subtitle container: [username]
        let subtitleContainerStackView = UIStackView()
        authorMetaContainerStackView.addArrangedSubview(subtitleContainerStackView)
        subtitleContainerStackView.axis = .horizontal
        subtitleContainerStackView.addArrangedSubview(usernameLabel)
        
        // status container: [status | image / video | audio]
        containerStackView.addArrangedSubview(statusContainerStackView)
        statusContainerStackView.axis = .vertical
        statusContainerStackView.spacing = 10
        statusContainerStackView.addArrangedSubview(activeTextLabel)
        activeTextLabel.setContentCompressionResistancePriority(.required - 2, for: .vertical)
        
        // action toolbar container
        containerStackView.addArrangedSubview(actionToolbarContainer)
        actionToolbarContainer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        headerContainerStackView.isHidden = true
    }
    
}

extension StatusView: AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { return Self.avatarImageSize }
    static var configurableAvatarImageCornerRadius: CGFloat { return 4 }
    var configurableAvatarImageView: UIImageView? { return nil }
    var configurableAvatarButton: UIButton? { return avatarButton }
    var configurableVerifiedBadgeImageView: UIImageView? { nil }
    
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct StatusView_Previews: PreviewProvider {
    
    static let avatarFlora = UIImage(named: "tiraya-adam-QfHEWqPelsc-unsplash")
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let statusView = StatusView()
                statusView.configure(
                    with: AvatarConfigurableViewConfiguration(
                        avatarImageURL: nil,
                        placeholderImage: avatarFlora
                    )
                )
                return statusView
            }
            .previewLayout(.fixed(width: 375, height: 200))
            UIViewPreview(width: 375) {
                let statusView = StatusView()
                statusView.configure(
                    with: AvatarConfigurableViewConfiguration(
                        avatarImageURL: nil,
                        placeholderImage: avatarFlora
                    )
                )
                statusView.headerContainerStackView.isHidden = false
                return statusView
            }
            .previewLayout(.fixed(width: 375, height: 200))
        }
    }
    
}

#endif

