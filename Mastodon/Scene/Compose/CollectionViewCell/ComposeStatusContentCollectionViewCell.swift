//
//  ComposeStatusContentCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import os.log
import UIKit
import Combine
import MetaTextView

final class ComposeStatusContentCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let statusView = StatusView()
    
    let statusContentWarningEditorView = StatusContentWarningEditorView()
    
    let textEditorViewContainerView = UIView()

    static let metaTextViewTag: Int = 333
    let metaText: MetaText = {
        let metaText = MetaText()
        metaText.textView.tag = ComposeStatusContentCollectionViewCell.metaTextViewTag
        metaText.textView.isScrollEnabled = false
        metaText.textView.keyboardType = .twitter
        metaText.textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        metaText.textView.attributedPlaceholder = {
            var attributes = metaText.textAttributes
            attributes[.foregroundColor] = Asset.Colors.Label.secondary.color
            return NSAttributedString(
                string: L10n.Scene.Compose.contentInputPlaceholder,
                attributes: attributes
            )
        }()
        return metaText
    }()

    // output
    let composeContent = PassthroughSubject<String, Never>()
    let contentWarningContent = PassthroughSubject<String, Never>()

    override func prepareForReuse() {
        super.prepareForReuse()

        metaText.delegate = nil
        metaText.textView.delegate = nil
    }
    
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
        layer.zPosition = 999
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
        
        textEditorViewContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textEditorViewContainerView)
        NSLayoutConstraint.activate([
            textEditorViewContainerView.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 10),
            textEditorViewContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textEditorViewContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: textEditorViewContainerView.bottomAnchor, constant: 10),
        ])
        textEditorViewContainerView.preservesSuperviewLayoutMargins = true
        
//        textEditorView.translatesAutoresizingMaskIntoConstraints = false
//        textEditorViewContainerView.addSubview(textEditorView)
//        NSLayoutConstraint.activate([
//            textEditorView.topAnchor.constraint(equalTo: textEditorViewContainerView.topAnchor),
//            textEditorView.leadingAnchor.constraint(equalTo: textEditorViewContainerView.readableContentGuide.leadingAnchor),
//            textEditorView.trailingAnchor.constraint(equalTo: textEditorViewContainerView.readableContentGuide.trailingAnchor),
//            textEditorView.bottomAnchor.constraint(equalTo: textEditorViewContainerView.bottomAnchor),
//            textEditorView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).priority(.defaultHigh),
//        ])
//        textEditorView.setContentCompressionResistancePriority(.required - 2, for: .vertical)

        metaText.textView.translatesAutoresizingMaskIntoConstraints = false
        textEditorViewContainerView.addSubview(metaText.textView)
        NSLayoutConstraint.activate([
            metaText.textView.topAnchor.constraint(equalTo: textEditorViewContainerView.topAnchor),
            metaText.textView.leadingAnchor.constraint(equalTo: textEditorViewContainerView.readableContentGuide.leadingAnchor),
            metaText.textView.trailingAnchor.constraint(equalTo: textEditorViewContainerView.readableContentGuide.trailingAnchor),
            metaText.textView.bottomAnchor.constraint(equalTo: textEditorViewContainerView.bottomAnchor),
            metaText.textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 88).priority(.defaultHigh),
        ])
        metaText.textView.setContentCompressionResistancePriority(.required - 2, for: .vertical)
                
        statusContentWarningEditorView.textView.delegate = self
        //textEditorView.changeObserver = self
        
        statusContentWarningEditorView.isHidden = true
        statusView.revealContentWarningButton.isHidden = true
    }

}

// MARK: - TextEditorViewChangeObserver
//extension ComposeStatusContentCollectionViewCell: TextEditorViewChangeObserver {
//    func textEditorView(_ textEditorView: TextEditorView, didChangeWithChangeResult changeResult: TextEditorViewChangeResult) {
//        defer {
//            textEditorViewChangeObserver?.textEditorView(textEditorView, didChangeWithChangeResult: changeResult)
//        }
//
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: text: %s", ((#file as NSString).lastPathComponent), #line, #function, textEditorView.text)
//        guard changeResult.isTextChanged else { return }
//        composeContent.send(textEditorView.text)
//    }
//}

// MARK: - UITextViewDelegate
extension ComposeStatusContentCollectionViewCell: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView === statusContentWarningEditorView.textView {
            // disable input line break
            guard text != "\n" else { return false }
        }
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
