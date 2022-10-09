//
//  PollOptionView+Configuration.swift
//  
//
//  Created by MainasuK on 2022-1-12.
//

import UIKit
import Combine
import CoreDataStack
import MetaTextKit
import MastodonCore
import MastodonUI

extension PollOptionView {
    public func configure(pollOption option: PollOption) {
        viewModel.objects.insert(option)
        
        // background
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.viewModel.roundedBackgroundViewColor = theme.systemElevatedBackgroundColor
            }
            .store(in: &disposeBag)
        // metaContent
        option.publisher(for: \.title)
            .map { title -> MetaContent? in
                return PlaintextMetaContent(string: title)
            }
            .assign(to: \.metaContent, on: viewModel)
            .store(in: &disposeBag)
        // percentage
        Publishers.CombineLatest(
            option.poll.publisher(for: \.votesCount),
            option.publisher(for: \.votesCount)
        )
        .map { pollVotesCount, optionVotesCount -> Double? in
            guard pollVotesCount > 0, optionVotesCount >= 0 else { return 0 }
            return Double(optionVotesCount) / Double(pollVotesCount)
        }
        .assign(to: \.percentage, on: viewModel)
        .store(in: &disposeBag)
        // $isExpire
        option.poll.publisher(for: \.expired)
            .assign(to: \.isExpire, on: viewModel)
            .store(in: &disposeBag)
        // isMultiple
        viewModel.isMultiple = option.poll.multiple
        
        let optionIndex = option.index
        let authorDomain = option.poll.status.author.domain
        let authorID = option.poll.status.author.id
        // isSelect, isPollVoted, isMyPoll
        Publishers.CombineLatest4(
            option.publisher(for: \.poll),
            option.publisher(for: \.votedBy),
            option.publisher(for: \.isSelected),
            viewModel.$authContext
        )
        .sink { [weak self] poll, optionVotedBy, isSelected, authContext in
            guard let self = self else { return }

            let domain = authContext?.mastodonAuthenticationBox.domain ?? ""
            let userID = authContext?.mastodonAuthenticationBox.userID ?? ""
            
            let options = poll.options
            let pollVoteBy = poll.votedBy ?? Set()

            let isMyPoll = authorDomain == domain
                        && authorID == userID

            let votedOptions = options.filter { option in
                let votedBy = option.votedBy ?? Set()
                return votedBy.contains(where: { $0.id == userID && $0.domain == domain })
            }
            let isRemoteVotedOption = votedOptions.contains(where: { $0.index == optionIndex })
            let isRemoteVotedPoll = pollVoteBy.contains(where: { $0.id == userID && $0.domain == domain })

            let isLocalVotedOption = isSelected

            let isSelect: Bool? = {
                if isLocalVotedOption {
                    return true
                } else if !votedOptions.isEmpty {
                    return isRemoteVotedOption ? true : false
                } else if isRemoteVotedPoll, votedOptions.isEmpty {
                    // the poll voted. But server not mark voted options
                    return nil
                } else {
                    return false
                }
            }()
            self.viewModel.isSelect = isSelect
            self.viewModel.isPollVoted = isRemoteVotedPoll
            self.viewModel.isMyPoll = isMyPoll
        }
        .store(in: &disposeBag)
        // appearance
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.checkmarkBackgroundView.backgroundColor = UIColor(dynamicProvider: { trailtCollection in
                    return trailtCollection.userInterfaceStyle == .light ? .white : theme.tableViewCellSelectionBackgroundColor
                })
            }
            .store(in: &disposeBag)
    }
}
