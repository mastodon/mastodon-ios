//
//  StatusMetricView.swift
//  
//
//  Created by MainasuK on 2022-1-17.
//

import os.log
import UIKit

protocol StatusMetricViewDelegate: AnyObject {
    func statusMetricView(_ statusMetricView: StatusMetricView, reblogButtonDidPressed button: UIButton)
    func statusMetricView(_ statusMetricView: StatusMetricView, favoriteButtonDidPressed button: UIButton)
}

public final class StatusMetricView: UIView {
    
    let logger = Logger(subsystem: "StatusMetricView", category: "View")
    
    weak var delegate: StatusMetricViewDelegate?
    
    // container
    public let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
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
    
    // meter
    public let meterContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        return stackView
    }()
    
    // reblog meter
    public let reblogButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        button.setTitle("0 reblog", for: .normal)
        return button
    }()
    
    // favorite meter
    public let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        button.setTitle("0 favorite", for: .normal)
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
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 12),
        ])
        
        containerStackView.addArrangedSubview(dateLabel)
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        containerStackView.addArrangedSubview(meterContainer)
        
        // meterContainer: H - [ reblogButton | favoriteButton ]
        meterContainer.addArrangedSubview(reblogButton)
        meterContainer.addArrangedSubview(favoriteButton)
        reblogButton.setContentHuggingPriority(.required - 2, for: .horizontal)
        reblogButton.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
        favoriteButton.setContentHuggingPriority(.required - 1, for: .horizontal)
        favoriteButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        reblogButton.addTarget(self, action: #selector(StatusMetricView.reblogButtonDidPressed(_:)), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(StatusMetricView.favoriteButtonDidPressed(_:)), for: .touchUpInside)
    }
}

extension StatusMetricView {

    @objc private func reblogButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusMetricView(self, reblogButtonDidPressed: sender)
    }
    
    @objc private func favoriteButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusMetricView(self, favoriteButtonDidPressed: sender)
    }
    
}
