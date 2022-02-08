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
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(cell: self)
        return viewModel
    }()
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = SettingsAppearanceTableViewCell.spacing
        return view
    }()
    
    let systemAppearanceView = AppearanceView(
        image: Asset.Settings.darkAuto.image,
        title: "Use System"     // TODO: i18n
    )
    let reallyDarkAppearanceView = AppearanceView(
        image: Asset.Settings.dark.image,
        title: "Really Dark"
    )
    let sortaDarkAppearanceView = AppearanceView(
        image: Asset.Settings.dark.image,
        title: "Sorta Dark"
    )
    let lightAppearanceView = AppearanceView(
        image: Asset.Settings.light.image,
        title: "Light"
    )
    
    var appearanceViews: [AppearanceView] {
        return [
            systemAppearanceView,
            reallyDarkAppearanceView,
            sortaDarkAppearanceView,
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
    }
    
}

extension SettingsAppearanceTableViewCell {
    
    // MARK: Private methods
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
        ])
        
        stackView.addArrangedSubview(systemAppearanceView)
        stackView.addArrangedSubview(reallyDarkAppearanceView)
        stackView.addArrangedSubview(sortaDarkAppearanceView)
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
        case reallyDarkAppearanceView:
            mode = .reallyDark
        case sortaDarkAppearanceView:
            mode = .sortaDark
        case lightAppearanceView:
            mode = .light
        default:
            assertionFailure()
            return
        }

        delegate?.settingsAppearanceTableViewCell(self, didSelectAppearanceMode: mode)
    }
}
