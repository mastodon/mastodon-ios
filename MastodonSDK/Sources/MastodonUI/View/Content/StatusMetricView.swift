//
//  StatusMetricView.swift
//  
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit
import MastodonAsset
import MastodonLocalization

protocol StatusMetricViewDelegate: AnyObject {
    func statusMetricView(_ statusMetricView: StatusMetricView, reblogButtonDidPressed button: UIButton)
    func statusMetricView(_ statusMetricView: StatusMetricView, favoriteButtonDidPressed button: UIButton)
    func statusMetricView(_ statusMetricView: StatusMetricView, didPressEditHistoryButton button: UIButton)
}

public final class StatusMetricView: UIView {

    weak var delegate: StatusMetricViewDelegate?

    var margin: CGFloat = 0 {
        didSet {
            dateAdaptiveMarginContainerView.margin = margin
            reblogButton.margin = margin
            favoriteButton.margin = margin
            editHistoryButton.margin = margin
        }
    }
    
    // container
    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        return stackView
    }()

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()
    
    // date
    let dateAdaptiveMarginContainerView = AdaptiveMarginContainerView()
    public let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.text = "Date"
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 2
        label.textColor = Asset.Colors.Label.secondary.color
        return label
    }()
    
    // reblog meter
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        return stackView
    }()

    public let reblogButton = StatusMetricRowView(iconImage: UIImage(systemName: "arrow.2.squarepath")!, text: L10n.Common.Controls.Status.Buttons.reblogsTitle, detailText: "")
    public let favoriteButton = StatusMetricRowView(iconImage: UIImage(systemName: "star"), text: L10n.Common.Controls.Status.Buttons.favoritesTitle, detailText: "")
    public let editHistoryButton = StatusMetricRowView(iconImage: Asset.Scene.EditHistory.edit.image, text: L10n.Common.Controls.Status.Buttons.editHistoryTitle)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
}

extension StatusMetricView {
    private func _init() {
        // container: H - [ dateLabel | meterContainer ]
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)

        separator.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(separator)

        reblogButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.addArrangedSubview(reblogButton)

        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.addArrangedSubview(favoriteButton)

        editHistoryButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.addArrangedSubview(editHistoryButton)

        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(buttonStackView)
        containerStackView.setCustomSpacing(11, after: buttonStackView)

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateAdaptiveMarginContainerView.translatesAutoresizingMaskIntoConstraints = false
        dateAdaptiveMarginContainerView.contentView = dateLabel
        containerStackView.addArrangedSubview(dateAdaptiveMarginContainerView)

        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 12),

            separator.heightAnchor.constraint(equalToConstant: 0.5),

            buttonStackView.widthAnchor.constraint(equalTo: containerStackView.widthAnchor),

            reblogButton.widthAnchor.constraint(equalTo: buttonStackView.widthAnchor),
            favoriteButton.widthAnchor.constraint(equalTo: reblogButton.widthAnchor),
            editHistoryButton.widthAnchor.constraint(equalTo: reblogButton.widthAnchor),
            dateLabel.widthAnchor.constraint(equalTo: reblogButton.widthAnchor),
        ])

        reblogButton.addTarget(self, action: #selector(StatusMetricView.didPressReblogButton(_:)), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(StatusMetricView.didPressFavoriteButton(_:)), for: .touchUpInside)
        editHistoryButton.addTarget(self, action: #selector(StatusMetricView.didPressEditHistoryButton(_:)), for: .touchUpInside)

    }
}

extension StatusMetricView {

    @objc private func didPressReblogButton(_ sender: UIButton) {
        delegate?.statusMetricView(self, reblogButtonDidPressed: sender)
    }
    
    @objc private func didPressFavoriteButton(_ sender: UIButton) {
        delegate?.statusMetricView(self, favoriteButtonDidPressed: sender)
    }

    @objc private func didPressEditHistoryButton(_ sender: UIButton) {
        delegate?.statusMetricView(self, didPressEditHistoryButton: sender)
    }

}
