//
//  SettingsAppearanceTableViewCell.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/8.
//

import UIKit

protocol SettingsAppearanceTableViewCellDelegate: class {
    func settingsAppearanceCell(_ view: SettingsAppearanceTableViewCell, didSelect: SettingsItem.AppearanceMode)
}

class AppearanceView: UIView {
    lazy var imageView: UIImageView = {
        let view = UIImageView()
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
        button.imageView?.tintColor = Asset.Colors.lightSecondaryText.color
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
                checkBox.imageView?.tintColor = Asset.Colors.lightBrandBlue.color
            } else {
                checkBox.imageView?.tintColor = Asset.Colors.lightSecondaryText.color
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
}

class SettingsAppearanceTableViewCell: UITableViewCell {
    weak var delegate: SettingsAppearanceTableViewCellDelegate?
    var appearance: SettingsItem.AppearanceMode = .automatic
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let automatic = AppearanceView(image: Asset.Settings.appearanceAutomatic.image,
                                   title: L10n.Scene.Settings.Section.Appearance.automatic)
    let light = AppearanceView(image: Asset.Settings.appearanceLight.image,
                               title: L10n.Scene.Settings.Section.Appearance.light)
    let dark = AppearanceView(image: Asset.Settings.appearanceDark.image,
                              title: L10n.Scene.Settings.Section.Appearance.dark)
    
    lazy var automaticTap: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        tapGestureRecognizer.addTarget(self, action: #selector(appearanceDidTap(sender:)))
        return tapGestureRecognizer
    }()
    
    lazy var lightTap: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        tapGestureRecognizer.addTarget(self, action: #selector(appearanceDidTap(sender:)))
        return tapGestureRecognizer
    }()
    
    lazy var darkTap: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        tapGestureRecognizer.addTarget(self, action: #selector(appearanceDidTap(sender:)))
        return tapGestureRecognizer
    }()
        
    // MARK: - Methods
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // remove seperator line in section of group tableview
        for subview in self.subviews {
            if subview != self.contentView && subview.frame.width == self.frame.width {
                subview.removeFromSuperview()
            }
        }
    }
    
    func update(with data: SettingsItem.AppearanceMode, delegate: SettingsAppearanceTableViewCellDelegate?) {
        appearance = data
        self.delegate = delegate
        
        automatic.selected = false
        light.selected = false
        dark.selected = false
        
        switch data {
        case .automatic:
            automatic.selected = true
        case .light:
            light.selected = true
        case .dark:
            dark.selected = true
        }
    }
    
    // MARK: Private methods
    private func setupUI() {
        backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        selectionStyle = .none
        contentView.addSubview(stackView)
        
        stackView.addArrangedSubview(automatic)
        stackView.addArrangedSubview(light)
        stackView.addArrangedSubview(dark)
        
        automatic.addGestureRecognizer(automaticTap)
        light.addGestureRecognizer(lightTap)
        dark.addGestureRecognizer(darkTap)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    // MARK: - Actions
    @objc func appearanceDidTap(sender: UIGestureRecognizer) {
        if sender == automaticTap {
            appearance = .automatic
        }
        
        if sender == lightTap {
            appearance = .light
        }
        
        if sender == darkTap {
            appearance = .dark
        }
        
        guard let delegate = self.delegate else { return }
        delegate.settingsAppearanceCell(self, didSelect: appearance)
    }
}
