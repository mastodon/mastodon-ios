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
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 14
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
    lazy var checkBox: UIButton = {
        let button = UIButton()
        button.isUserInteractionEnabled = false
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        button.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        button.imageView?.tintColor = Asset.Colors.Label.secondary.color
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 10
        view.distribution = .equalSpacing
        return view
    }()

    var selected: Bool = false {
        didSet {
            checkBox.isSelected = selected
            if selected {
                checkBox.imageView?.tintColor = Asset.Colors.brandBlue.color
            } else {
                checkBox.imageView?.tintColor = Asset.Colors.Label.secondary.color
            }
        }
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
        get {
            return [titleLabel.text, checkBox.accessibilityLabel]
                .compactMap { $0 }
                .joined(separator: ", ")
        }
        set { }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods
    private func setupUI() {
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(checkBox)

        addSubview(stackView)
        translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 218.0 / 100.0),
        ])
    }

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
