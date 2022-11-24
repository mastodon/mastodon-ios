//
//  AppearanceView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-6.
//

import UIKit
import MastodonAsset
import MastodonLocalization
import MastodonUI

class AppearanceView: UIView {
    
    let imageViewShadowBackgroundContainer = ShadowBackgroundContainer()
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 4
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
    
    lazy var checkmarkButton: UIButton = {
        let button = UIButton()
        button.isUserInteractionEnabled = false
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        button.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        button.imageView?.tintColor = Asset.Colors.Label.primary.color
        button.imageView?.contentMode = .scaleAspectFill
        return button
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
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageViewShadowBackgroundContainer.addSubview(imageView)
        imageView.pinToParent()
        imageViewShadowBackgroundContainer.cornerRadius = 4
        
        stackView.addArrangedSubview(imageViewShadowBackgroundContainer)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(checkmarkButton)

        addSubview(stackView)
        translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.pinToParent()
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 121.0 / 100.0),        // height / width
        ])
    }
    
    private func configureForSelection() {
        if selected {
            accessibilityTraits.insert(.selected)
        } else {
            accessibilityTraits.remove(.selected)
        }
        
        checkmarkButton.isSelected = selected
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
