//
//  ComposeStatusContentCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import os.log
import UIKit
import Combine
import TwitterTextEditor

final class ComposeStatusContentCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let statusView = StatusView()
    
    let statusContentWarningEditorView = StatusContentWarningEditorView()
    
    let textEditorView: TextEditorView = {
        let textEditorView = TextEditorView()
        textEditorView.font = .preferredFont(forTextStyle: .body)
        textEditorView.scrollView.isScrollEnabled = false
        textEditorView.isScrollEnabled = false
        textEditorView.placeholderText = L10n.Scene.Compose.contentInputPlaceholder
        textEditorView.keyboardType = .twitter
        return textEditorView
    }()
    
    // output
    let composeContent = PassthroughSubject<String, Never>()
    let contentWarningContent = PassthroughSubject<String, Never>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposeStatusContentCollectionViewCell {
    
    private func _init() {
        // selectionStyle = .none
        preservesSuperviewLayoutMargins = true
        
        statusContentWarningEditorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusContentWarningEditorView)
        NSLayoutConstraint.activate([
            statusContentWarningEditorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            statusContentWarningEditorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statusContentWarningEditorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        statusContentWarningEditorView.preservesSuperviewLayoutMargins = true
        statusContentWarningEditorView.containerBackgroundView.isHidden = false
        
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: statusContentWarningEditorView.bottomAnchor, constant: 20),
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
            contentView.bottomAnchor.constraint(equalTo: textEditorView.bottomAnchor, constant: 10),
            textEditorView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).priority(.defaultHigh),
        ])
        textEditorView.setContentCompressionResistancePriority(.required - 2, for: .vertical)
                
        statusContentWarningEditorView.textView.delegate = self
        textEditorView.changeObserver = self
        
        statusContentWarningEditorView.containerView.isHidden = true
    }
    
}

// MARK: - TextEditorViewChangeObserver
extension ComposeStatusContentCollectionViewCell: TextEditorViewChangeObserver {
    func textEditorView(_ textEditorView: TextEditorView, didChangeWithChangeResult changeResult: TextEditorViewChangeResult) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: text: %s", ((#file as NSString).lastPathComponent), #line, #function, textEditorView.text)
        guard changeResult.isTextChanged else { return }
        composeContent.send(textEditorView.text)
    }
}

// MARK: - UITextViewDelegate
extension ComposeStatusContentCollectionViewCell: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // disable input line break
        guard text != "\n" else { return false }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: text: %s", ((#file as NSString).lastPathComponent), #line, #function, textView.text)
        guard textView === statusContentWarningEditorView.textView else { return }
        // replace line break with space
        textView.text = textView.text.replacingOccurrences(of: "\n", with: " ")
        contentWarningContent.send(textView.text)
    }
    
}
