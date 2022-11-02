//
//  SearchHistoryTableHeaderView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-14.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI

protocol SearchHistoryTableHeaderViewDelegate: AnyObject {
    func searchHistoryTableHeaderView(_ searchHistoryTableHeaderView: SearchHistoryTableHeaderView, clearSearchHistoryButtonDidPressed button: UIButton)
}

final class SearchHistoryTableHeaderView: UIView {

    let logger = Logger(subsystem: "SearchHistory", category: "UI")

    weak var delegate: SearchHistoryTableHeaderViewDelegate?
    var disposeBag = Set<AnyCancellable>()

    let recentSearchesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.Search.Searching.recentSearch
        return label
    }()

    let clearSearchHistoryButton: HighlightDimmableButton = {
        let button = HighlightDimmableButton(type: .custom)
        button.expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.setTitleColor(Asset.Colors.brand.color, for: .normal)
        button.setTitle(L10n.Scene.Search.Searching.clear, for: .normal)
        return button
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

extension SearchHistoryTableHeaderView {
    private func _init() {
        preservesSuperviewLayoutMargins = true

        recentSearchesLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(recentSearchesLabel)
        NSLayoutConstraint.activate([
            recentSearchesLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            recentSearchesLabel.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            bottomAnchor.constraint(equalTo: recentSearchesLabel.bottomAnchor, constant: 16),
        ])

        clearSearchHistoryButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(clearSearchHistoryButton)
        NSLayoutConstraint.activate([
            clearSearchHistoryButton.centerYAnchor.constraint(equalTo: recentSearchesLabel.centerYAnchor),
            clearSearchHistoryButton.leadingAnchor.constraint(equalTo: recentSearchesLabel.trailingAnchor),
            clearSearchHistoryButton.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
        ])
        clearSearchHistoryButton.setContentHuggingPriority(.defaultHigh + 10, for: .horizontal)

        clearSearchHistoryButton.addTarget(self, action: #selector(SearchHistoryTableHeaderView.clearSearchHistoryButtonDidPressed(_:)), for: .touchUpInside)

        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)
    }
}

extension SearchHistoryTableHeaderView {
    @objc private func clearSearchHistoryButtonDidPressed(_ sender: UIButton) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.searchHistoryTableHeaderView(self, clearSearchHistoryButtonDidPressed: sender)
    }
}

extension SearchHistoryTableHeaderView {
    private func setupBackgroundColor(theme: Theme) {
        backgroundColor = theme.systemGroupedBackgroundColor
    }
}
