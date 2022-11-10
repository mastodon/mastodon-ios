//
//  ComposeToolbarView.swift
//  ShareActionExtension
//
//  Created by MainasuK Cirno on 2021-7-19.
//

import os.log
import UIKit
import Combine
import MastodonSDK
import MastodonAsset
import MastodonLocalization
import MastodonCore
import MastodonUI

protocol ComposeToolbarViewDelegate: AnyObject {
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, contentWarningButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, visibilityButtonDidPressed sender: UIButton, visibilitySelectionType type: ComposeToolbarView.VisibilitySelectionType)
}

final class ComposeToolbarView: UIView {

    var disposeBag = Set<AnyCancellable>()

    static let toolbarButtonSize: CGSize = CGSize(width: 44, height: 44)
    static let toolbarHeight: CGFloat = 44

    weak var delegate: ComposeToolbarViewDelegate?

    let contentWarningButton: UIButton = {
        let button = HighlightDimmableButton()
        ComposeToolbarView.configureToolbarButtonAppearance(button: button)
        button.setImage(UIImage(systemName: "exclamationmark.shield", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
        button.accessibilityLabel = L10n.Scene.Compose.Accessibility.enableContentWarning
        return button
    }()

    let visibilityButton: UIButton = {
        let button = HighlightDimmableButton()
        ComposeToolbarView.configureToolbarButtonAppearance(button: button)
        button.setImage(UIImage(systemName: "person.3", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)), for: .normal)
        button.accessibilityLabel = L10n.Scene.Compose.Accessibility.postVisibilityMenu
        return button
    }()

    let characterCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.text = "500"
        label.textColor = Asset.Colors.Label.secondary.color
        label.accessibilityLabel = L10n.A11y.Plural.Count.inputLimitRemains(500)
        return label
    }()

    let activeVisibilityType = CurrentValueSubject<VisibilitySelectionType, Never>(.public)

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension ComposeToolbarView {

    private func _init() {
        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            layoutMarginsGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 8), // tweak button margin offset
        ])

        let buttons = [
            contentWarningButton,
            visibilityButton,
        ]
        buttons.forEach { button in
            button.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(button)
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 44),
                button.heightAnchor.constraint(equalToConstant: 44),
            ])
        }

        characterCountLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(characterCountLabel)
        NSLayoutConstraint.activate([
            characterCountLabel.topAnchor.constraint(equalTo: topAnchor),
            characterCountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor, constant: 8),
            characterCountLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            characterCountLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        characterCountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        contentWarningButton.addTarget(self, action: #selector(ComposeToolbarView.contentWarningButtonDidPressed(_:)), for: .touchUpInside)
        visibilityButton.menu = createVisibilityContextMenu(interfaceStyle: traitCollection.userInterfaceStyle)
        visibilityButton.showsMenuAsPrimaryAction = true

        updateToolbarButtonUserInterfaceStyle()

        // update menu when selected visibility type changed
        activeVisibilityType
            .receive(on: RunLoop.main)
            .sink { [weak self] type in
                guard let self = self else { return }
                self.visibilityButton.menu = self.createVisibilityContextMenu(interfaceStyle: self.traitCollection.userInterfaceStyle)
            }
            .store(in: &disposeBag)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateToolbarButtonUserInterfaceStyle()
    }

}

extension ComposeToolbarView {
    private func setupBackgroundColor(theme: Theme) {
        backgroundColor = theme.composeToolbarBackgroundColor
    }
}

extension ComposeToolbarView {
    enum MediaSelectionType: String {
        case camera
        case photoLibrary
        case browse
    }

    enum VisibilitySelectionType: String, CaseIterable {
        case `public`
        // TODO: remove unlisted option from codebase
        // case unlisted
        case `private`
        case direct

        var title: String {
            switch self {
            case .public: return L10n.Scene.Compose.Visibility.public
            // case .unlisted: return L10n.Scene.Compose.Visibility.unlisted
            case .private: return L10n.Scene.Compose.Visibility.private
            case .direct: return L10n.Scene.Compose.Visibility.direct
            }
        }

        func image(interfaceStyle: UIUserInterfaceStyle) -> UIImage {
            switch self {
            case .public: return UIImage(systemName: "globe", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .medium))!
            // case .unlisted: return UIImage(systemName: "eye.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))!
            case .private:
                switch interfaceStyle {
                case .light: return UIImage(systemName: "person.3", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))!
                default: return UIImage(systemName: "person.3.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))!
                }
            case .direct: return UIImage(systemName: "at", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .regular))!
            }
        }

        var visibility: Mastodon.Entity.Status.Visibility {
            switch self {
            case .public: return .public
            // case .unlisted: return .unlisted
            case .private: return .private
            case .direct: return .direct
            }
        }
    }
}

extension ComposeToolbarView {

    private static func configureToolbarButtonAppearance(button: UIButton) {
        button.tintColor = ThemeService.tintColor
        button.setBackgroundImage(.placeholder(size: ComposeToolbarView.toolbarButtonSize, color: .systemFill), for: .highlighted)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 5
        button.layer.cornerCurve = .continuous
    }

    private func updateToolbarButtonUserInterfaceStyle() {
        switch traitCollection.userInterfaceStyle {
        case .light:
            contentWarningButton.setImage(UIImage(systemName: "exclamationmark.shield", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!, for: .normal)

        case .dark:
            contentWarningButton.setImage(UIImage(systemName: "exclamationmark.shield.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!, for: .normal)

        default:
            assertionFailure()
        }

        visibilityButton.menu = createVisibilityContextMenu(interfaceStyle: traitCollection.userInterfaceStyle)
    }

    private func createVisibilityContextMenu(interfaceStyle: UIUserInterfaceStyle) -> UIMenu {
        let children: [UIMenuElement] = VisibilitySelectionType.allCases.map { type in
            let state: UIMenuElement.State = activeVisibilityType.value == type ? .on : .off
            return UIAction(title: type.title, image: type.image(interfaceStyle: interfaceStyle), identifier: nil, discoverabilityTitle: nil, attributes: [], state: state) { [weak self] action in
                guard let self = self else { return }
                os_log(.info, "%{public}s[%{public}ld], %{public}s: visibilitySelectionType: %s", ((#file as NSString).lastPathComponent), #line, #function, type.rawValue)
                self.delegate?.composeToolbarView(self, visibilityButtonDidPressed: self.visibilityButton, visibilitySelectionType: type)
            }
        }
        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: children)
    }

}

extension ComposeToolbarView {

    @objc private func contentWarningButtonDidPressed(_ sender: UIButton) {
        os_log(.info, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.composeToolbarView(self, contentWarningButtonDidPressed: sender)
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ComposeToolbarView_Previews: PreviewProvider {

    static var previews: some View {
        UIViewPreview(width: 375) {
            let toolbarView = ComposeToolbarView()
            toolbarView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toolbarView.widthAnchor.constraint(equalToConstant: 375).priority(.defaultHigh),
                toolbarView.heightAnchor.constraint(equalToConstant: 64).priority(.defaultHigh),
            ])
            return toolbarView
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }

}

#endif

