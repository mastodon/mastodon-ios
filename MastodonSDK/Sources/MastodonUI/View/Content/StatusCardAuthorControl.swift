import UIKit
import MastodonAsset
import MastodonSDK

class StatusCardAuthorControl: UIControl {
    let authorLabel: UILabel
    let avatarImage: AvatarImageView
    private let contentStackView: UIStackView

    public override init(frame: CGRect) {
        authorLabel = UILabel()
        authorLabel.textAlignment = .center
        authorLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 16, weight: .bold))
        authorLabel.isUserInteractionEnabled = false

        avatarImage = AvatarImageView()
        avatarImage.translatesAutoresizingMaskIntoConstraints = false
        avatarImage.configure(cornerConfiguration: AvatarImageView.CornerConfiguration(corner: .fixed(radius: 4)))
        avatarImage.isUserInteractionEnabled = false

        contentStackView = UIStackView(arrangedSubviews: [avatarImage, authorLabel])
        contentStackView.alignment = .center
        contentStackView.spacing = 6
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.layoutMargins = UIEdgeInsets(horizontal: 6, vertical: 8)
        contentStackView.isUserInteractionEnabled = false

        super.init(frame: frame)

        addSubview(contentStackView)
        setupConstraints()
        backgroundColor = Asset.Colors.Button.userFollowing.color
        layer.cornerRadius = 10
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 6),
            bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 6),

            avatarImage.widthAnchor.constraint(equalToConstant: 16),
            avatarImage.widthAnchor.constraint(equalTo: avatarImage.heightAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    public func configure(with account: Mastodon.Entity.Account) {
        authorLabel.text = account.displayNameWithFallback
        avatarImage.configure(with: account.avatarImageURL())
    }
}
