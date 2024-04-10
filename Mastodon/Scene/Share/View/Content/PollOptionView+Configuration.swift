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
import MastodonSDK

extension PollOptionView {
    public func configure(pollOption option: MastodonPollOption) {
        let poll = option.poll
        let status = option.poll.status
        
        // metaContent
        option.$title
            .map { title -> MetaContent? in
                return PlaintextMetaContent(string: title)
            }
            .assign(to: \.metaContent, on: viewModel)
            .store(in: &disposeBag)
        
        // percentage
        Publishers.CombineLatest(
            poll.$votersCount,
            option.$votesCount
        )
        .map { pollVotersCount, optionVotesCount -> Double? in
            guard let pollVotersCount, pollVotersCount > 0, let optionVotesCount, optionVotesCount >= 0 else { return 0 }
            return Double(optionVotesCount) / Double(pollVotersCount)
        }
        .assign(to: \.percentage, on: viewModel)
        .store(in: &disposeBag)
        
        // $isExpire
        poll.$expired
            .assign(to: \.isExpire, on: viewModel)
            .store(in: &disposeBag)
        
        // isMultiple
        viewModel.isMultiple = poll.multiple
        
        let authContext = viewModel.authContext
        
        let authorDomain = status?.entity.account.domain ?? ""
        let authorID = status?.entity.account.id ?? ""
        // isSelect, isPollVoted, isMyPoll
        let domain = authContext?.mastodonAuthenticationBox.domain ?? ""
        let userID = authContext?.mastodonAuthenticationBox.userID ?? ""

        let isMyPoll = authorDomain == domain
                    && authorID == userID

        self.viewModel.isSelect = option.isSelected
        self.viewModel.isPollVoted = poll.voted == true
        self.viewModel.isMyPoll = isMyPoll

        // appearance
        checkmarkBackgroundView.backgroundColor = UIColor(dynamicProvider: { trailtCollection in
            return trailtCollection.userInterfaceStyle == .light ? .white : SystemTheme.tableViewCellSelectionBackgroundColor
        })

    }
}

extension PollOptionView {
    public func configure(historyPollOption option: Mastodon.Entity.StatusEdit.Poll.Option) {
        // background
        viewModel.roundedBackgroundViewColor = SystemTheme.systemElevatedBackgroundColor
        // metaContent
        viewModel.metaContent = PlaintextMetaContent(string: option.title)
        // show left-hand-side dots, otherwise view looks "incomplete"
        viewModel.selectState = .off
        // appearance
        checkmarkBackgroundView.backgroundColor = UIColor(dynamicProvider: { trailtCollection in
            return trailtCollection.userInterfaceStyle == .light ? .white : SystemTheme.tableViewCellSelectionBackgroundColor
        })
    }
}
