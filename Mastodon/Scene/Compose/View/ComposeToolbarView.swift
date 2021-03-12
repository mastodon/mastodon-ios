//
//  ComposeToolbarView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-12.
//

import UIKit

protocol ComposeToolbarViewDelegate: class {
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, cameraButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, gifButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, atButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, topicButtonDidPressed sender: UIButton)
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, locationButtonDidPressed sender: UIButton)
}

final class ComposeToolbarView: UIView {
    
    static let toolbarHeight: CGFloat = 44
    
    weak var delegate: ComposeToolbarViewDelegate?
    
    let mediaButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = Asset.Colors.Button.normal.color
        button.setImage(UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
        return button
    }()
    
    let pollButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = Asset.Colors.Button.normal.color
        button.setImage(UIImage(systemName: "list.bullet", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)), for: .normal)
        return button
    }()
    
    let emojiButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = Asset.Colors.Button.normal.color
        button.setImage(UIImage(systemName: "face.smiling", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
        return button
    }()
    
    let contentWarningButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = Asset.Colors.Button.normal.color
        button.setImage(UIImage(systemName: "exclamationmark.shield", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
        return button
    }()
    
    let visibilityButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = Asset.Colors.Button.normal.color
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
        
        mediaButton.addTarget(self, action: #selector(ComposeToolbarView.cameraButtonDidPressed(_:)), for: .touchUpInside)
        pollButton.addTarget(self, action: #selector(ComposeToolbarView.gifButtonDidPressed(_:)), for: .touchUpInside)
        emojiButton.addTarget(self, action: #selector(ComposeToolbarView.atButtonDidPressed(_:)), for: .touchUpInside)
        contentWarningButton.addTarget(self, action: #selector(ComposeToolbarView.topicButtonDidPressed(_:)), for: .touchUpInside)
        visibilityButton.addTarget(self, action: #selector(ComposeToolbarView.locationButtonDidPressed(_:)), for: .touchUpInside)
    }
}


extension ComposeToolbarView {
    
    @objc private func cameraButtonDidPressed(_ sender: UIButton) {
        delegate?.composeToolbarView(self, cameraButtonDidPressed: sender)
    }
    
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

