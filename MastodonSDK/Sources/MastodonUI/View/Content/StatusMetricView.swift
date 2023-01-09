//
//  StatusMetricView.swift
//  
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit
import MastodonAsset

protocol StatusMetricViewDelegate: AnyObject {
    func statusMetricView(_ statusMetricView: StatusMetricView, reblogButtonDidPressed button: UIButton)
    func statusMetricView(_ statusMetricView: StatusMetricView, favoriteButtonDidPressed button: UIButton)
    func statusMetricView(_ statusMetricView: StatusMetricView, didPressEditHistoryButton button: UIButton)
}

public final class StatusMetricView: UIView {

    weak var delegate: StatusMetricViewDelegate?
    
    // container
    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        return stackView
    }()
    
    // date
    public let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.text = "Date"
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 2
        return label
    }()
    
    // reblog meter
    public let reblogButton: StatusMetricRowView = {
        let button = StatusMetricRowView(iconImage: Asset.Arrow.repeat.image, text: "Reblogs", detailText: "10")
        return button
    }()
    
    // favorite meter
    public let favoriteButton: StatusMetricRowView = {
        let button = StatusMetricRowView(iconImage: UIImage(systemName: "star"), text: "Favorites", detailText: "10")
        return button
    }()

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

        reblogButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(reblogButton)

        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(favoriteButton)

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(dateLabel)

        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 12),

            reblogButton.widthAnchor.constraint(equalTo: containerStackView.widthAnchor),
            favoriteButton.widthAnchor.constraint(equalTo: reblogButton.widthAnchor),
            dateLabel.widthAnchor.constraint(equalTo: reblogButton.widthAnchor),
        ])


        reblogButton.addTarget(self, action: #selector(StatusMetricView.didPressReblogButton(_:)), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(StatusMetricView.didPressFavoriteButton(_:)), for: .touchUpInside)
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
