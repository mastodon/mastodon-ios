//
//  NewsTableViewCell.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit

public final class NewsTableViewCell: UITableViewCell {
    
    public let newsView = NewsView()
    
    let separatorLine = UIView.separatorLine
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        newsView.prepareForReuse()
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension NewsTableViewCell {
    
    private func _init() {
        newsView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(newsView)
        NSLayoutConstraint.activate([
            newsView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            newsView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            newsView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: newsView.bottomAnchor, constant: 16),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
        
        isAccessibilityElement = true
        accessibilityElements = [
            newsView
        ]
    }
    
}
