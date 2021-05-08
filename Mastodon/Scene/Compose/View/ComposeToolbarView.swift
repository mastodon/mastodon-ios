//
//  ComposeToolbarView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-12.
//

import os.log
import UIKit
import MastodonSDK

protocol ComposeToolbarViewDelegate: AnyObject {
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, cameraButtonDidPressed sender: UIButton, mediaSelectionType type: ComposeToolbarView.MediaSelectionType)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, pollButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, emojiButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, contentWarningButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, visibilityButtonDidPressed sender: UIButton, visibilitySelectionType type: ComposeToolbarView.VisibilitySelectionType)
}

final class ComposeToolbarView: UIView {
    
    static let toolbarButtonSize: CGSize = CGSize(width: 44, height: 44)
    static let toolbarHeight: CGFloat = 44
    
    weak var delegate: ComposeToolbarViewDelegate?
    
    let mediaButton: UIButton = {
        let button = HighlightDimmableButton()
        ComposeToolbarView.configureToolbarButtonAppearance(button: button)
        button.setImage(UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
        return button
    }()
    
    let pollButton: UIButton = {
        let button = HighlightDimmableButton(type: .custom)
        ComposeToolbarView.configureToolbarButtonAppearance(button: button)
        button.setImage(UIImage(systemName: "list.bullet", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)), for: .normal)
        return button
    }()
    
    let emojiButton: UIButton = {
        let button = HighlightDimmableButton()
        ComposeToolbarView.configureToolbarButtonAppearance(button: button)
        let image = Asset.Human.faceSmilingAdaptive.image
            .af.imageScaled(to: CGSize(width: 20, height: 20))
            .withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        return button
    }()
    
    let contentWarningButton: UIButton = {
        let button = HighlightDimmableButton()
        ComposeToolbarView.configureToolbarButtonAppearance(button: button)
        button.setImage(UIImage(systemName: "exclamationmark.shield", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
        return button
    }()
    
    let visibilityButton: UIButton = {
        let button = HighlightDimmableButton()
        ComposeToolbarView.configureToolbarButtonAppearance(button: button)
        button.setImage(UIImage(systemName: "person.3", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)), for: .normal)
        return button
    }()
    
    let characterCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.text = "500"
        label.textColor = Asset.Colors.Label.secondary.color
        return label
    }()
    
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
        // magic keyboard color (iOS 14):
        // light with white background: RGB 214 216 222
        // dark with black background: RGB 43 43 43
        backgroundColor = Asset.Scene.Compose.toolbarBackground.color
        
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
            mediaButton,
            pollButton,
            emojiButton,
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
        
        mediaButton.menu = createMediaContextMenu()
        mediaButton.showsMenuAsPrimaryAction = true
        pollButton.addTarget(self, action: #selector(ComposeToolbarView.pollButtonDidPressed(_:)), for: .touchUpInside)
        emojiButton.addTarget(self, action: #selector(ComposeToolbarView.emojiButtonDidPressed(_:)), for: .touchUpInside)
        contentWarningButton.addTarget(self, action: #selector(ComposeToolbarView.contentWarningButtonDidPressed(_:)), for: .touchUpInside)
        visibilityButton.menu = createVisibilityContextMenu(interfaceStyle: traitCollection.userInterfaceStyle)
        visibilityButton.showsMenuAsPrimaryAction = true
        
        updateToolbarButtonUserInterfaceStyle()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateToolbarButtonUserInterfaceStyle()
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
        case unlisted
        case `private`
        case direct
        
        var title: String {
            switch self {
            case .public: return L10n.Scene.Compose.Visibility.public
            case .unlisted: return L10n.Scene.Compose.Visibility.unlisted
            case .private: return L10n.Scene.Compose.Visibility.private
            case .direct: return L10n.Scene.Compose.Visibility.direct
            }
        }
        
        func image(interfaceStyle: UIUserInterfaceStyle) -> UIImage {
            switch self {
            case .public:
                switch interfaceStyle {
                case .light: return UIImage(systemName: "person.3", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))!
                default: return UIImage(systemName: "person.3.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))!
                }
            case .unlisted: return UIImage(systemName: "eye.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))!
            case .private: return UIImage(systemName: "person.crop.circle.badge.plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))!
            case .direct: return UIImage(systemName: "at", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .regular))!
            }
        }
        
        var visibility: Mastodon.Entity.Status.Visibility {
            switch self {
            case .public: return .public
            case .unlisted: return .unlisted
            case .private: return .private
            case .direct: return .direct
            }
        }
    }
}

extension ComposeToolbarView {

    private static func configureToolbarButtonAppearance(button: UIButton) {
        button.tintColor = Asset.Colors.Button.normal.color
        button.setBackgroundImage(.placeholder(size: ComposeToolbarView.toolbarButtonSize, color: .systemFill), for: .highlighted)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 5
        button.layer.cornerCurve = .continuous
    }
    
    private func updateToolbarButtonUserInterfaceStyle() {
        switch traitCollection.userInterfaceStyle {
        case .light:
            mediaButton.setImage(UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!, for: .normal)
            contentWarningButton.setImage(UIImage(systemName: "exclamationmark.shield", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!, for: .normal)

        case .dark:
            mediaButton.setImage(UIImage(systemName: "photo.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!, for: .normal)
            contentWarningButton.setImage(UIImage(systemName: "exclamationmark.shield.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))!, for: .normal)

        default:
            assertionFailure()
        }
        
        visibilityButton.menu = createVisibilityContextMenu(interfaceStyle: traitCollection.userInterfaceStyle)
    }
    
    private func createMediaContextMenu() -> UIMenu {
        var children: [UIMenuElement] = []
        let photoLibraryAction = UIAction(title: L10n.Scene.Compose.MediaSelection.photoLibrary, image: UIImage(systemName: "rectangle.on.rectangle"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
            guard let self = self else { return }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: mediaSelectionType: .photoLibaray", ((#file as NSString).lastPathComponent), #line, #function)
            self.delegate?.composeToolbarView(self, cameraButtonDidPressed: self.mediaButton, mediaSelectionType: .photoLibrary)
        }
        children.append(photoLibraryAction)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAction(title: L10n.Scene.Compose.MediaSelection.camera, image: UIImage(systemName: "camera"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] _ in
                guard let self = self else { return }
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: mediaSelectionType: .camera", ((#file as NSString).lastPathComponent), #line, #function)
                self.delegate?.composeToolbarView(self, cameraButtonDidPressed: self.mediaButton, mediaSelectionType: .camera)
            })
            children.append(cameraAction)
        }
        let browseAction = UIAction(title: L10n.Scene.Compose.MediaSelection.browse, image: UIImage(systemName: "ellipsis"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
            guard let self = self else { return }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: mediaSelectionType: .browse", ((#file as NSString).lastPathComponent), #line, #function)
            self.delegate?.composeToolbarView(self, cameraButtonDidPressed: self.mediaButton, mediaSelectionType: .browse)
        }
        children.append(browseAction)
        
        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: children)
    }
    
    private func createVisibilityContextMenu(interfaceStyle: UIUserInterfaceStyle) -> UIMenu {
        let children: [UIMenuElement] = VisibilitySelectionType.allCases.map { type in
            UIAction(title: type.title, image: type.image(interfaceStyle: interfaceStyle), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] action in
                guard let self = self else { return }
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: visibilitySelectionType: %s", ((#file as NSString).lastPathComponent), #line, #function, type.rawValue)
                self.delegate?.composeToolbarView(self, visibilityButtonDidPressed: self.visibilityButton, visibilitySelectionType: type)
            }
        }
        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: children)
    }
    
}

extension ComposeToolbarView {
    
    @objc private func pollButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.composeToolbarView(self, pollButtonDidPressed: sender)
    }
    
    @objc private func emojiButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.composeToolbarView(self, emojiButtonDidPressed: sender)
    }
    
    @objc private func contentWarningButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
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

