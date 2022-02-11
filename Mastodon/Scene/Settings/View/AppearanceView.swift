//
//  AppearanceView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-6.
//

import UIKit
import MastodonAsset
import MastodonLocalization

class AppearanceView: UIView {
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        view.layer.cornerCurve = .continuous
        // accessibility
        view.accessibilityIgnoresInvertColors = true
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = Asset.Colors.Label.primary.color
        label.textAlignment = .center
        return label
    }()

    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        view.distribution = .equalSpacing
        return view
    }()

    var selected: Bool = false {
        didSet { setNeedsLayout() }
    }
    
    // MARK: - Methods
    init(image: UIImage?, title: String) {
        super.init(frame: .zero)
        setupUI()

        imageView.image = image
        titleLabel.text = title
    }
    
    override var isAccessibilityElement: Bool {
        get { return true }
        set { }
        
    }
    override var accessibilityLabel: String? {
        get { titleLabel.text }
        set { }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension AppearanceView {

    private func setupUI() {
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)

        addSubview(stackView)
        translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 120.0 / 90.0),
        ])
    }
    
    private func configureForSelection() {
        if selected {
            imageView.layer.borderWidth = 3
            imageView.layer.borderColor = Asset.Colors.Label.primary.color.cgColor
            accessibilityTraits.insert(.selected)
        } else {
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = Asset.Colors.Label.primaryReverse.color.cgColor
            accessibilityTraits.remove(.selected)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        configureForSelection()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setNeedsLayout()
    }
    
}

extension AppearanceView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.alpha = 0.5
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.33) {
            self.alpha = 1
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.33) {
            self.alpha = 1
        }
    }
}
