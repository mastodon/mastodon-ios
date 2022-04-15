//
//  TrendView.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import MastodonAsset

public final class TrendView: UIView {
    
    let container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        return stackView
    }()
    
    let infoContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    let lineChartContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    let primaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        label.textColor = Asset.Colors.Label.primary.color
        return label
    }()
    
    let secondaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.textColor = Asset.Colors.Label.secondary.color
        return label
    }()
    
    let lineChartView = LineChartView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TrendView {
    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 11),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 11),
        ])

        // container: H - [ info container | padding | line chart container ]
        container.addArrangedSubview(infoContainer)
        
        // info container: V - [ primary | secondary ]
        infoContainer.addArrangedSubview(primaryLabel)
        infoContainer.addArrangedSubview(secondaryLabel)
        
        // padding
        let padding = UIView()
        container.addArrangedSubview(padding)
        
        // line chart
        container.addArrangedSubview(lineChartContainer)
        
        let lineChartViewTopPadding = UIView()
        let lineChartViewBottomPadding = UIView()
        lineChartViewTopPadding.translatesAutoresizingMaskIntoConstraints = false
        lineChartViewBottomPadding.translatesAutoresizingMaskIntoConstraints = false
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        lineChartContainer.addArrangedSubview(lineChartViewTopPadding)
        lineChartContainer.addArrangedSubview(lineChartView)
        lineChartContainer.addArrangedSubview(lineChartViewBottomPadding)
        NSLayoutConstraint.activate([
            lineChartView.widthAnchor.constraint(equalToConstant: 50),
            lineChartView.heightAnchor.constraint(equalToConstant: 26),
            lineChartViewTopPadding.heightAnchor.constraint(equalTo: lineChartViewBottomPadding.heightAnchor),
        ])
    }
}

