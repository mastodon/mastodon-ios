//
//  SettingsAppearanceTableViewCell.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/8.
//

import UIKit
import Combine

protocol SettingsAppearanceTableViewCellDelegate: AnyObject {
    func settingsAppearanceCell(_ cell: SettingsAppearanceTableViewCell, didSelectAppearanceMode appearanceMode: SettingsItem.AppearanceMode)
}

class SettingsAppearanceTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()

    static let spacing: CGFloat = 18
    
    weak var delegate: SettingsAppearanceTableViewCellDelegate?
    var appearance: SettingsItem.AppearanceMode = .automatic
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = SettingsAppearanceTableViewCell.spacing
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let automatic = AppearanceView(image: Asset.Settings.darkAuto.image,
                                   title: L10n.Scene.Settings.Section.Appearance.automatic)
    let light = AppearanceView(image: Asset.Settings.light.image,
                               title: L10n.Scene.Settings.Section.Appearance.light)
    let dark = AppearanceView(image: Asset.Settings.dark.image,
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
    }
        
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
        
        // remove separator line in section of group tableview
        for subview in self.subviews {
            if subview != self.contentView && subview.frame.width == self.frame.width {
                subview.removeFromSuperview()
            }
        }

        setupAsset(theme: ThemeService.shared.currentTheme.value)
    }
    
    func update(with data: SettingsItem.AppearanceMode) {
        appearance = data
        
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
        backgroundColor = .clear
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
            stackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
        ])

        setupAsset(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupAsset(theme: theme)
            }
            .store(in: &disposeBag)
    }

    private func setupAsset(theme: Theme) {
        let aspectRatio = Asset.Settings.light.image.size
        let width = floor(frame.width - 2 * SettingsAppearanceTableViewCell.spacing) / 3
        let height = width / aspectRatio.width * aspectRatio.height
        let size = CGSize(width: width, height: height)

        light.imageView.image = Asset.Settings.light.image.af.imageAspectScaled(toFill: size, scale: UIScreen.main.scale)
        switch theme.themeName {
        case .mastodon:
            automatic.imageView.image = Asset.Settings.darkAuto.image.af.imageAspectScaled(toFill: size, scale: UIScreen.main.scale)
            dark.imageView.image = Asset.Settings.dark.image.af.imageAspectScaled(toFill: size, scale: UIScreen.main.scale)
        case .system:
            automatic.imageView.image = Asset.Settings.blackAuto.image.af.imageAspectScaled(toFill: size, scale: UIScreen.main.scale)
            dark.imageView.image = Asset.Settings.black.image.af.imageAspectScaled(toFill: size, scale: UIScreen.main.scale)
        }
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
        delegate.settingsAppearanceCell(self, didSelectAppearanceMode: appearance)
    }
}
