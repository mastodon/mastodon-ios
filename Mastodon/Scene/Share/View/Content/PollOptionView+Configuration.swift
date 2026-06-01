//
//  PollOptionView+Configuration.swift
//  
//
//  Created by MainasuK on 2022-1-12.
//

import UIKit
import Combine
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
        
        let authenticationBox = viewModel.authenticationBox
        
        let authorDomain = status?.entity.account.domain ?? ""
        let authorID = status?.entity.account.id ?? ""
        // isSelect, isPollVoted, isMyPoll
        let domain = authenticationBox?.domain ?? ""
        let userID = authenticationBox?.userID ?? ""

        let isMyPoll = authorDomain == domain
                    && authorID == userID

        self.viewModel.isSelect = option.isSelected
        self.viewModel.isPollVoted = poll.voted == true
        self.viewModel.isMyPoll = isMyPoll

        // appearance
        checkmarkBackgroundView.backgroundColor = SystemTheme.tableViewCellSelectionBackgroundColor
    }
    
    public func configure(poll: Mastodon.Entity.Poll, option pollOption: Mastodon.Entity.Poll.Option, isMyPoll: Bool) {
        // metaContent
        viewModel.metaContent = PlaintextMetaContent(string: pollOption.title)
        
        // percentage
        let denominator = poll.votersCount ?? poll.votesCount
        let optionVotesCount = pollOption.votesCount ?? 0
        if denominator > 0, optionVotesCount >= 0 {
            viewModel.percentage = Double(optionVotesCount) / Double(denominator)
        } else {
            viewModel.percentage = 0
        }
        
        // expiration
        viewModel.isExpire = poll.expired
        
        // isMultiple
        viewModel.isMultiple = poll.multiple

        if let isSelectedIndex = poll.options.firstIndex(of: pollOption) {
            viewModel.isSelect = poll.ownVotes?.contains(isSelectedIndex) ?? false
        } else {
            viewModel.isSelect = false
        }
        viewModel.isPollVoted = poll.voted == true
        viewModel.isMyPoll = isMyPoll

        // appearance
        checkmarkBackgroundView.backgroundColor = SystemTheme.tableViewCellSelectionBackgroundColor
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
        checkmarkBackgroundView.backgroundColor = SystemTheme.tableViewCellSelectionBackgroundColor
    }
}
