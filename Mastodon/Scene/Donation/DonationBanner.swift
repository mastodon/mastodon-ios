// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import MastodonAsset

class DonationBanner: UIView {
    private enum Constants {
        static let padding: CGFloat = 16
        static let textToButtonPadding: CGFloat = 48
    }
    
    private var campaign: Mastodon.Entity.DonationCampaign?
    private lazy var backgroundImageView: UIImageView = {
        UIImageView(image: Asset.Asset.scribble.image)
    }()
    private let messageLabel = UILabel()
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(.init(systemName: "xmark"), for: .normal)
        return button
    }()

    init() {
        super.init(frame: .zero)
        setupViews()
    }
    
    var onClose: (() -> Void)?
    var onShowDonationDialog: (() -> Void)?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(campaign: Mastodon.Entity.DonationCampaign) {
        let spacing = " "
        let stringValue = "\(campaign.bannerMessage)\(spacing)\(campaign.bannerButtonText)"
        let attributedString = NSMutableAttributedString(string: stringValue)
        let fullTextRange = NSRange(location: 0, length: stringValue.length)
        let buttonRange = NSRange(location: campaign.bannerMessage.length + spacing.length, length: campaign.bannerButtonText.length)
        attributedString.addAttributes(
            [
                .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 14, weight: .regular)),
                .foregroundColor: Asset.Colors.Secondary.onContainer.color
            ],
            range: fullTextRange
        )
        attributedString.addAttributes(
            [
                .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 14, weight: .bold)),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: Asset.Colors.goldenrod.color,
                .foregroundColor: Asset.Colors.goldenrod.color
            ],
            range: buttonRange
        )
        messageLabel.attributedText = attributedString
    }
    
    private func setupViews() {
        backgroundColor = Asset.Colors.Secondary.container.color
        addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.alpha = 0.08
        
        closeButton.tintColor = Asset.Colors.Secondary.onContainer.color
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
    
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
        addSubview(messageLabel)
        addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: Constants.padding),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.padding),
            messageLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -Constants.padding*2),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding/2),
            closeButton.topAnchor.constraint(equalTo: topAnchor),
            closeButton.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    @objc
    private func closeButtonPressed(_ sender: Any?) {
        onClose?()
    }
}
