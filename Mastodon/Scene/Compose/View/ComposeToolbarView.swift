//
//  ComposeToolbarView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-12.
//

import UIKit

protocol ComposeToolbarViewDelegate: class {
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, cameraButtonDidPressed sender: UIButton, mediaSelectionType: ComposeToolbarView.MediaSelectionType)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, gifButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, atButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, topicButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, locationButtonDidPressed sender: UIButton)
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
        button.setImage(UIImage(systemName: "face.smiling", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
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
        backgroundColor = .secondarySystemBackground
        
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
        
        mediaButton.menu = createMediaContextMenu()
        mediaButton.showsMenuAsPrimaryAction = true
        pollButton.addTarget(self, action: #selector(ComposeToolbarView.gifButtonDidPressed(_:)), for: .touchUpInside)
        emojiButton.addTarget(self, action: #selector(ComposeToolbarView.atButtonDidPressed(_:)), for: .touchUpInside)
        contentWarningButton.addTarget(self, action: #selector(ComposeToolbarView.topicButtonDidPressed(_:)), for: .touchUpInside)
        visibilityButton.addTarget(self, action: #selector(ComposeToolbarView.locationButtonDidPressed(_:)), for: .touchUpInside)
    }
}

extension ComposeToolbarView {
    enum MediaSelectionType: String {
        case camera
        case photoLibrary
        case browse
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
    
    private func createMediaContextMenu() -> UIMenu {
        var children: [UIMenuElement] = []
        let photoLibraryAction = UIAction(title: L10n.Scene.Compose.MediaSelection.photoLibrary, image: UIImage(systemName: "rectangle.on.rectangle"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.composeToolbarView(self, cameraButtonDidPressed: self.mediaButton, mediaSelectionType: .photoLibrary)
        }
        children.append(photoLibraryAction)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAction(title: L10n.Scene.Compose.MediaSelection.camera, image: UIImage(systemName: "camera"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.composeToolbarView(self, cameraButtonDidPressed: self.mediaButton, mediaSelectionType: .camera)
            })
            children.append(cameraAction)
        }
        let browseAction = UIAction(title: L10n.Scene.Compose.MediaSelection.browse, image: UIImage(systemName: "ellipsis"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.composeToolbarView(self, cameraButtonDidPressed: self.mediaButton, mediaSelectionType: .browse)
        }
        children.append(browseAction)
        
        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: children)
    }
    
}


extension ComposeToolbarView {
    
    @objc private func gifButtonDidPressed(_ sender: UIButton) {
        delegate?.composeToolbarView(self, gifButtonDidPressed: sender)
    }
    
    @objc private func atButtonDidPressed(_ sender: UIButton) {
        delegate?.composeToolbarView(self, atButtonDidPressed: sender)
    }
    
    @objc private func topicButtonDidPressed(_ sender: UIButton) {
        delegate?.composeToolbarView(self, topicButtonDidPressed: sender)
    }
    
    @objc private func locationButtonDidPressed(_ sender: UIButton) {
        delegate?.composeToolbarView(self, locationButtonDidPressed: sender)
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ComposeToolbarView_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            let tootbarView = ComposeToolbarView()
            tootbarView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tootbarView.widthAnchor.constraint(equalToConstant: 375).priority(.defaultHigh),
                tootbarView.heightAnchor.constraint(equalToConstant: 64).priority(.defaultHigh),
            ])
            return tootbarView
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
    
}

#endif

