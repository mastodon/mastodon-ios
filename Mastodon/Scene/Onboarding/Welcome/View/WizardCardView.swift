//
//  WizardCardView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import UIKit

final class WizardCardView: UIView {
    
    static let bubbleArrowHeight: CGFloat = 17
    static let bubbleArrowWidth: CGFloat = 20
    
    let contentView = UIView()

    let backgroundShapeLayer = CAShapeLayer()
    var arrowRectCorner: UIRectCorner = .bottomRight
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        label.textColor = .black
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 13, weight: .regular))
        label.textColor = .black
        label.numberOfLines = 0
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

extension WizardCardView {
    private func _init() {
        layer.masksToBounds = false
        layer.addSublayer(backgroundShapeLayer)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: WizardCardView.bubbleArrowHeight),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: WizardCardView.bubbleArrowHeight),
        ])
        
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 2
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 7),
            contentView.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor, constant: 24),
            contentView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 5),
        ])
        
        containerStackView.addArrangedSubview(titleLabel)
        containerStackView.addArrangedSubview(descriptionLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let radius: CGFloat = 5
        let rect = contentView.frame
        let path = UIBezierPath()
        
        switch arrowRectCorner {
        case .bottomRight:
            path.move(to: CGPoint(x: rect.maxX - WizardCardView.bubbleArrowWidth, y: rect.maxY + radius))
            path.addArc(withCenter: CGPoint(x: rect.minX, y: rect.maxY), radius: radius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
            path.addArc(withCenter: CGPoint(x: rect.minX, y: rect.minY), radius: radius, startAngle: .pi, endAngle: .pi / 2 * 3, clockwise: true)
            path.addArc(withCenter: CGPoint(x: rect.maxX, y: rect.minY), radius: radius, startAngle: .pi / 2 * 3, endAngle: .pi * 2, clockwise: true)
            path.addLine(to: CGPoint(x: rect.maxX + radius, y: rect.maxY + radius + WizardCardView.bubbleArrowHeight))
            path.close()
        case .bottomLeft:
            path.move(to: CGPoint(x: rect.minX + WizardCardView.bubbleArrowWidth, y: rect.maxY + radius))
            path.addArc(withCenter: CGPoint(x: rect.maxX, y: rect.maxY), radius: radius, startAngle: .pi / 2, endAngle: 0, clockwise: false)
            path.addArc(withCenter: CGPoint(x: rect.maxX, y: rect.minY), radius: radius, startAngle: 0, endAngle: -.pi / 2, clockwise: false)
            path.addArc(withCenter: CGPoint(x: rect.minX, y: rect.minY), radius: radius, startAngle: -.pi / 2, endAngle: -.pi, clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX - radius, y: rect.maxY + radius + WizardCardView.bubbleArrowHeight))
            path.close()
        default:
            assertionFailure("FIXME")
        }
        
        backgroundShapeLayer.lineCap = .round
        backgroundShapeLayer.lineJoin = .round
        backgroundShapeLayer.lineWidth = 3
        backgroundShapeLayer.strokeColor = UIColor.white.cgColor
        backgroundShapeLayer.fillColor = UIColor.white.cgColor
        backgroundShapeLayer.path = path.cgPath
    }
    
    override var isAccessibilityElement: Bool {
        get { true }
        set { }
    }
    
    override var accessibilityLabel: String? {
        get {
            return [
                titleLabel.text,
                descriptionLabel.text
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        }
        set { }
    }
    
    override var accessibilityHint: String? {
        get {
            return L10n.Scene.Wizard.accessibilityHint
        }
        set { }
    }
}
