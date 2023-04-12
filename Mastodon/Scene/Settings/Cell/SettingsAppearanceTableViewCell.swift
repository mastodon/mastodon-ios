//
//  SettingsAppearanceTableViewCell.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/8.
//

import UIKit
import Combine
import MastodonAsset
import MastodonLocalization

protocol SettingsAppearanceTableViewCellDelegate: AnyObject {
    func settingsAppearanceTableViewCell(_ cell: SettingsAppearanceTableViewCell, didSelectAppearanceMode appearanceMode: SettingsItem.AppearanceMode)
}

class SettingsAppearanceTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    static let spacing: CGFloat = 28
    
    weak var delegate: SettingsAppearanceTableViewCellDelegate?
    
    public private(set) var viewModel = ViewModel()
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = SettingsAppearanceTableViewCell.spacing
        return view
    }()
    
    let systemAppearanceView = AppearanceView(
        image: Asset.Settings.automatic.image,
        title: L10n.Scene.Settings.Section.Appearance.automatic
    )
    let darkAppearanceView = AppearanceView(
        image: Asset.Settings.dark.image,
        title: L10n.Scene.Settings.Section.Appearance.dark
    )
    let lightAppearanceView = AppearanceView(
        image: Asset.Settings.light.image,
        title: L10n.Scene.Settings.Section.Appearance.light
    )
    
    var appearanceViews: [AppearanceView] {
        return [
            systemAppearanceView,
            darkAppearanceView,
            lightAppearanceView,
        ]
    }
        
    override func prepareForReuse() {
        super.prepareForReuse()
    
        disposeBag.removeAll()
        observations.removeAll()
        viewModel.prepareForReuse()
    }
        
    // MARK: - Methods
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        viewModel.bind(cell: self)
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
        
        // remove grouped style table corner radius
        layer.cornerRadius = 0
    }
    
}

extension SettingsAppearanceTableViewCell {
    
    // MARK: Private methods
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        stackView.pinToParent()
        
        stackView.addArrangedSubview(systemAppearanceView)
        stackView.addArrangedSubview(darkAppearanceView)
        stackView.addArrangedSubview(lightAppearanceView)
        
        appearanceViews.forEach { view in
            let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
            view.addGestureRecognizer(tapGestureRecognizer)
            tapGestureRecognizer.addTarget(self, action: #selector(SettingsAppearanceTableViewCell.appearanceViewDidPressed(_:)))
        }
    }

}

// MARK: - Actions
extension SettingsAppearanceTableViewCell {
    @objc func appearanceViewDidPressed(_ sender: UITapGestureRecognizer) {
        let mode: SettingsItem.AppearanceMode
        
        switch sender.view {
        case systemAppearanceView:
            mode = .system
        case darkAppearanceView:
            mode = .dark
        case lightAppearanceView:
            mode = .light
        default:
            assertionFailure()
            return
        }

        delegate?.settingsAppearanceTableViewCell(self, didSelectAppearanceMode: mode)
    }
}
