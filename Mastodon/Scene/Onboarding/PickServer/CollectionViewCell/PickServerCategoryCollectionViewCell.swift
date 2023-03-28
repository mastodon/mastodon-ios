//
//  PickServerCategoryCollectionViewCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit
import MastodonSDK
import MastodonAsset
import MastodonUI
import MastodonLocalization

class PickServerCategoryCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "PickServerCategoryCollectionViewCell"

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = Asset.Colors.Label.secondary.color
        return label
    }()

    let chevron: UIImageView = {
        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        return chevron
    }()

    let menuButton: UIButton = {
        let menuButton = UIButton()
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        return menuButton
    }()

    private let container: UIStackView = {
        let container = UIStackView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .horizontal
        container.spacing = 4
        container.distribution = .fillProportionally
        container.alignment = .center
        return container
    }()
        
    var observations = Set<NSKeyValueObservation>()
    override func prepareForReuse() {
        super.prepareForReuse()
        observations.removeAll()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)

        container.addArrangedSubview(titleLabel)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        container.addArrangedSubview(chevron)

        menuButton.addTarget(self, action: #selector(PickServerCategoryCollectionViewCell.didPressButton(_:)), for: .touchUpInside)

        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 1.0
        applyCornerRadius(radius: 18)

        contentView.addSubview(container)
        contentView.addSubview(menuButton)

        setupConstraints()
    }

    private func setupConstraints() {

        var constraints = [
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            contentView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 12),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 6),

            chevron.heightAnchor.constraint(equalToConstant: 16),
            chevron.widthAnchor.constraint(equalToConstant: 14),
        ]

        constraints.append(contentsOf: menuButton.pinToParent())
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    //MARK: - Actions

    @objc func didPressButton(_ sender: Any) {
        invalidateIntrinsicContentSize()
    }

}
