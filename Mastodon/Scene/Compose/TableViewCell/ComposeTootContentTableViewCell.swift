//
//  ComposeTootContentTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import TwitterTextEditor

final class ComposeTootContentTableViewCell: UITableViewCell {
    
    let statusView = StatusView()
    let textEditorView: TextEditorView = {
        let textEditorView = TextEditorView()
        textEditorView.font = .preferredFont(forTextStyle: .body)
//        textEditorView.scrollView.isScrollEnabled = false
        textEditorView.isScrollEnabled = false
        return textEditorView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposeTootContentTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statusView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
        ])
        statusView.statusContainerStackView.isHidden = true
        statusView.actionToolbarContainer.isHidden = true
        
        textEditorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textEditorView)
        NSLayoutConstraint.activate([
            textEditorView.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 10),
            textEditorView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            textEditorView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: textEditorView.bottomAnchor, constant: 20),
            textEditorView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).priority(.defaultHigh),
        ])
        
        // let containerStackView = UIStackView()
        // containerStackView.axis = .vertical
        // containerStackView.spacing = 8
        // containerStackView.translatesAutoresizingMaskIntoConstraints = false
        // contentView.addSubview(containerStackView)
        // NSLayoutConstraint.activate([
        //     containerStackView.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 10),
        //     containerStackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
        //     containerStackView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
        //     contentView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 20),
        // ])
        
        // TODO:
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
    }
    
}

extension ComposeTootContentTableViewCell {
    
}
