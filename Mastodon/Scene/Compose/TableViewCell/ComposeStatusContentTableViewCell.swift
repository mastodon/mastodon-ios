//
//  ComposeStatusContentTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import Combine
import TwitterTextEditor

final class ComposeStatusContentTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let statusView = StatusView()
    
    let textEditorView: TextEditorView = {
        let textEditorView = TextEditorView()
        textEditorView.font = .preferredFont(forTextStyle: .body)
        textEditorView.scrollView.isScrollEnabled = false
        textEditorView.isScrollEnabled = false
        textEditorView.placeholderText = L10n.Scene.Compose.contentInputPlaceholder
        textEditorView.keyboardType = .twitter
        return textEditorView
    }()
    
    let composeContent = PassthroughSubject<String, Never>()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposeStatusContentTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statusView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
        ])
        statusView.statusContainerStackView.isHidden = true
        statusView.actionToolbarContainer.isHidden = true
        statusView.nameTrialingDotLabel.isHidden = true
        statusView.dateLabel.isHidden = true
        
        statusView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        statusView.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        
        textEditorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textEditorView)
        NSLayoutConstraint.activate([
            textEditorView.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 10),
            textEditorView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            textEditorView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: textEditorView.bottomAnchor, constant: 20),
            textEditorView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).priority(.defaultHigh),
        ])
        textEditorView.setContentCompressionResistancePriority(.required - 2, for: .vertical)
        
        // TODO:
        
        textEditorView.changeObserver = self
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
    }
    
}

extension ComposeStatusContentTableViewCell {
    
}

// MARK: - UITextViewDelegate
extension ComposeStatusContentTableViewCell: TextEditorViewChangeObserver {
    func textEditorView(_ textEditorView: TextEditorView, didChangeWithChangeResult changeResult: TextEditorViewChangeResult) {
        guard changeResult.isTextChanged else { return }
        composeContent.send(textEditorView.text)
    }
}
