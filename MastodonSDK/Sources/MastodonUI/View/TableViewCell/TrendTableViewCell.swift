//
//  TrendTableViewCell.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit

public final class TrendTableViewCell: UITableViewCell {
    
    public let trendView = TrendView()
    
    let separatorLine = UIView.separatorLine
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        configureSeparator(style: .inset)
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

extension TrendTableViewCell {
    
    private func _init() {
        trendView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(trendView)
        NSLayoutConstraint.activate([
            trendView.topAnchor.constraint(equalTo: contentView.topAnchor),
            trendView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            trendView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            trendView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        configureSeparator(style: .inset)
        
        accessibilityElements = [trendView]
    }
    
}

extension TrendTableViewCell {
    
    public enum SeparatorStyle {
        case edge
        case inset
    }
    
    public func configureSeparator(style: SeparatorStyle) {
        separatorLine.removeFromSuperview()
        separatorLine.removeConstraints(separatorLine.constraints)
        
        switch style {
        case .edge:
            separatorLine.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(separatorLine)
            NSLayoutConstraint.activate([
                separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
            ])
        case .inset:
            separatorLine.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(separatorLine)
            NSLayoutConstraint.activate([
                separatorLine.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
            ])
        }
    }
    
}
