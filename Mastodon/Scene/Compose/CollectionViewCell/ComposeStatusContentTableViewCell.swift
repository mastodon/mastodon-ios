//
//  ComposeStatusContentTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-28.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import UITextView_Placeholder

final class ComposeStatusContentTableViewCell: UITableViewCell {

    let logger = Logger(subsystem: "ComposeStatusContentTableViewCell", category: "UI")

    var disposeBag = Set<AnyCancellable>()

    let statusView = ReplicaStatusView()

    let statusContentWarningEditorView = StatusContentWarningEditorView()

    let textEditorViewContainerView = UIView()

    static let metaTextViewTag: Int = 333
    let metaText: MetaText = {
        let metaText = MetaText()
        metaText.textView.backgroundColor = .clear
        metaText.textView.isScrollEnabled = false
        metaText.textView.keyboardType = .twitter
        metaText.textView.textDragInteraction?.isEnabled = false    // disable drag for link and attachment
        metaText.textView.textContainer.lineFragmentPadding = 10    // leading inset
        metaText.textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        metaText.textView.attributedPlaceholder = {
            var attributes = metaText.textAttributes
            attributes[.foregroundColor] = Asset.Colors.Label.secondary.color
            return NSAttributedString(
                string: L10n.Scene.Compose.contentInputPlaceholder,
                attributes: attributes
            )
        }()
        metaText.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 5
            style.paragraphSpacing = 8
            return style
        }()
        metaText.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)),
            .foregroundColor: Asset.Colors.Label.primary.color,
        ]
        metaText.linkAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold)),
            .foregroundColor: Asset.Colors.brandBlue.color,
        ]
        return metaText
    }()

    // output
    let contentWarningContent = PassthroughSubject<String, Never>()

    override func prepareForReuse() {
        super.prepareForReuse()

        metaText.delegate = nil
        metaText.textView.delegate = nil
    }

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
        layer.zPosition = 999
        backgroundColor = .clear
        preservesSuperviewLayoutMargins = true

        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        containerStackView.preservesSuperviewLayoutMargins = true

        containerStackView.addArrangedSubview(statusContentWarningEditorView)
        statusContentWarningEditorView.setContentHuggingPriority(.required - 1, for: .vertical)

        let statusContainerView = UIView()
        statusContainerView.preservesSuperviewLayoutMargins = true
        containerStackView.addArrangedSubview(statusContainerView)
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusContainerView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: statusContainerView.topAnchor, constant: 20),
            statusView.leadingAnchor.constraint(equalTo: statusContainerView.layoutMarginsGuide.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: statusContainerView.layoutMarginsGuide.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: statusContainerView.bottomAnchor),
        ])

        containerStackView.addArrangedSubview(textEditorViewContainerView)
        metaText.textView.translatesAutoresizingMaskIntoConstraints = false
        textEditorViewContainerView.addSubview(metaText.textView)
        NSLayoutConstraint.activate([
            metaText.textView.topAnchor.constraint(equalTo: textEditorViewContainerView.topAnchor),
            metaText.textView.leadingAnchor.constraint(equalTo: textEditorViewContainerView.layoutMarginsGuide.leadingAnchor),
            metaText.textView.trailingAnchor.constraint(equalTo: textEditorViewContainerView.layoutMarginsGuide.trailingAnchor),
            metaText.textView.bottomAnchor.constraint(equalTo: textEditorViewContainerView.bottomAnchor),
            metaText.textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 88).priority(.defaultHigh),
        ])
        statusContentWarningEditorView.textView.delegate = self

        statusView.nameTrialingDotLabel.isHidden = true
        statusView.dateLabel.isHidden = true
        statusContentWarningEditorView.isHidden = true
        statusView.statusContainerStackView.isHidden = true
    }

}

// MARK: - UITextViewDelegate
extension ComposeStatusContentTableViewCell: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        switch textView {
        case statusContentWarningEditorView.textView:
            // disable input line break
            guard text != "\n" else { return false }
            return true
        default:
            assertionFailure()
            return true
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): text: \(textView.text ?? "<nil>")")
        guard textView === statusContentWarningEditorView.textView else { return }
        // replace line break with space
        textView.text = textView.text.replacingOccurrences(of: "\n", with: " ")
        contentWarningContent.send(textView.text)
    }

}

