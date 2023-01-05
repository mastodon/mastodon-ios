//
//  FollowedTagsTableViewCell.swift
//  Mastodon
//
//  Created by Marcus Kida on 24.11.22.
//

import UIKit
import CoreDataStack

final class FollowedTagsTableViewCell: UITableViewCell {
    private var hashtagView: HashtagTimelineHeaderView!
    private let separatorLine = UIView.separatorLine
    private weak var viewModel: FollowedTagsViewModel?
    private weak var hashtag: Tag?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func prepareForReuse() {
        hashtagView.removeFromSuperview()
        viewModel = nil
        hashtagView = nil
        super.prepareForReuse()
        setup()
    }
}

private extension FollowedTagsTableViewCell {
    func setup() {
        selectionStyle = .none
        
        hashtagView = HashtagTimelineHeaderView()
        hashtagView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(hashtagView)
        contentView.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            hashtagView.heightAnchor.constraint(equalToConstant: 118).priority(.required),
            hashtagView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hashtagView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hashtagView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hashtagView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
        
        hashtagView.onButtonTapped = { [weak self] in
            guard let self = self, let tag = self.hashtag else { return }
            self.viewModel?.followOrUnfollow(tag)
        }
    }
}

extension FollowedTagsTableViewCell {
    func populate(with tag: Tag) {
        self.hashtag = tag
        hashtagView.update(HashtagTimelineHeaderView.Data.from(tag))
    }
    
    func setup(_ viewModel: FollowedTagsViewModel) {
        self.viewModel = viewModel
    }
}
