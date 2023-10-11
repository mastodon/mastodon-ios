// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset
import AlamofireImage

class AboutInstanceTableHeaderView: UIView {
    let thumbnailImageView: UIImageView

    init() {
        thumbnailImageView = UIImageView(image: Asset.Settings.aboutInstancePlaceholder.image)
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: .zero)

        addSubview(thumbnailImageView)

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            thumbnailImageView.topAnchor.constraint(equalTo: topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor),
            bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 16),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func updateImage(with thumbnailURL: URL, completion: (() -> Void)? = nil) {
        thumbnailImageView.af.setImage(withURL: thumbnailURL, placeholderImage: Asset.Settings.aboutInstancePlaceholder.image, completion: { _ in
            completion?()
        })
    }
}
