//
//  TrendCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-18.
//

import UIKit
import Combine
import MetaTextKit
import MastodonAsset

final class TrendCollectionViewCell: UICollectionViewCell {
    
    var _disposeBag = Set<AnyCancellable>()
    
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
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

extension TrendCollectionViewCell {
    
    private func _init() {
        ThemeService.shared.currentTheme
            .map { $0.secondarySystemGroupedBackgroundColor }
            .sink { [weak self] backgroundColor in
                guard let self = self else { return }
                self.backgroundColor = backgroundColor
                self.setNeedsUpdateConfiguration()
            }
            .store(in: &_disposeBag)
        
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 11),
        ])
        
        container.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        container.isLayoutMarginsRelativeArrangement = true

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
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        
        var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
        backgroundConfiguration.backgroundColorTransformer = .init { _ in
            if state.isHighlighted || state.isSelected {
                return ThemeService.shared.currentTheme.value.tableViewCellSelectionBackgroundColor
            }
            return ThemeService.shared.currentTheme.value.secondarySystemGroupedBackgroundColor
        }
        self.backgroundConfiguration = backgroundConfiguration
    }
    
}
