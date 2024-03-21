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
    public func configure(pollOption option: Mastodon.Entity.Poll.Option, status: MastodonStatus?) {
        guard let poll = status?.entity.poll else {
            assertionFailure("PollOption to be configured is expected to be part of Poll with Status")
            return
        }

//        viewModel.objects.insert(option)
        
        // metaContent
        viewModel.metaContent = PlaintextMetaContent(string: option.title)
//        option.publisher(for: \.title)
//            .map { title -> MetaContent? in
//                return PlaintextMetaContent(string: title)
//            }
//            .assign(to: \.metaContent, on: viewModel)
//            .store(in: &disposeBag)
        
        // percentage
        viewModel.percentage = {
            let pollVotersCount = poll.votersCount ?? 0
            let optionVotesCount = option.votesCount ?? 0
            guard pollVotersCount > 0, optionVotesCount >= 0 else { return 0 }
            return Double(optionVotesCount) / Double(pollVotersCount)
        }()
//        Publishers.CombineLatest(
//            poll.publisher(for: \.votersCount),
//            option.publisher(for: \.votesCount)
//        )
//        .map { pollVotersCount, optionVotesCount -> Double? in
//            guard pollVotersCount > 0, optionVotesCount >= 0 else { return 0 }
//            return Double(optionVotesCount) / Double(pollVotersCount)
//        }
//        .assign(to: \.percentage, on: viewModel)
//        .store(in: &disposeBag)
        // $isExpire
        viewModel.isExpire = poll.expired
//        poll.publisher(for: \.expired)
//            .assign(to: \.isExpire, on: viewModel)
//            .store(in: &disposeBag)
        // isMultiple
        viewModel.isMultiple = poll.multiple
        
        let authContext = viewModel.authContext
        
        let optionIndex = poll.options.firstIndex(of: option)
        let authorDomain = status?.entity.account.domain ?? ""
        let authorID = status?.entity.account.id ?? ""
        // isSelect, isPollVoted, isMyPoll
        let domain = authContext?.mastodonAuthenticationBox.domain ?? ""
        let userID = authContext?.mastodonAuthenticationBox.userID ?? ""
        
        let options = poll.options
//        let pollVoteBy = poll.votedBy ?? Set()
//
//        let isMyPoll = authorDomain == domain
//                    && authorID == userID
//
//        let votedOptions = options.filter { option in
//            let votedBy = option.votedBy ?? Set()
//            return votedBy.contains(where: { $0.id == userID && $0.domain == domain })
//        }
//        let isRemoteVotedOption = votedOptions.contains(where: { $0.index == optionIndex })
//        let isRemoteVotedPoll = pollVoteBy.contains(where: { $0.id == userID && $0.domain == domain })
//
//        let isLocalVotedOption = isSelected
//
//        let isSelect: Bool? = {
//            if isLocalVotedOption {
//                return true
//            } else if !votedOptions.isEmpty {
//                return isRemoteVotedOption ? true : false
//            } else if isRemoteVotedPoll, votedOptions.isEmpty {
//                // the poll voted. But server not mark voted options
//                return nil
//            } else {
//                return false
//            }
//        }()
        self.viewModel.isSelect = false
        self.viewModel.isPollVoted = poll.voted == true
        self.viewModel.isMyPoll = poll.ownVotes != nil
        
//        viewModel.$authContext
//            .compactMap { authContext -> AnyPublisher<Mastodon.Response.Content<Mastodon.API.Polls>, Error>? in
//                guard let authContext else { return nil }
//                return Mastodon.API.Polls.poll(
//                    session: .shared,
//                    domain: authContext.mastodonAuthenticationBox.domain,
//                    pollID: poll.id,
//                    authorization: authContext.mastodonAuthenticationBox.userAuthorization
//                )
//            }
//            .receive(on: DispatchQueue.main)
//            .sink(receiveValue: { value in
//                
//            })
//            .store(in: &disposeBag)
        
//        Publishers.CombineLatest4(
//            option.publisher(for: \.poll),
//            option.publisher(for: \.votedBy),
//            option.publisher(for: \.isSelected),
//            viewModel.$authContext
//        )
//        .sink { [weak self] poll, optionVotedBy, isSelected, authContext in
//            guard let self = self, let poll = poll else { return }
//
//            let domain = authContext?.mastodonAuthenticationBox.domain ?? ""
//            let userID = authContext?.mastodonAuthenticationBox.userID ?? ""
//            
//            let options = poll.options
//            let pollVoteBy = poll.votedBy ?? Set()
//
//            let isMyPoll = authorDomain == domain
//                        && authorID == userID
//
//            let votedOptions = options.filter { option in
//                let votedBy = option.votedBy ?? Set()
//                return votedBy.contains(where: { $0.id == userID && $0.domain == domain })
//            }
//            let isRemoteVotedOption = votedOptions.contains(where: { $0.index == optionIndex })
//            let isRemoteVotedPoll = pollVoteBy.contains(where: { $0.id == userID && $0.domain == domain })
//
//            let isLocalVotedOption = isSelected
//
//            let isSelect: Bool? = {
//                if isLocalVotedOption {
//                    return true
//                } else if !votedOptions.isEmpty {
//                    return isRemoteVotedOption ? true : false
//                } else if isRemoteVotedPoll, votedOptions.isEmpty {
//                    // the poll voted. But server not mark voted options
//                    return nil
//                } else {
//                    return false
//                }
//            }()
//            self.viewModel.isSelect = isSelect
//            self.viewModel.isPollVoted = isRemoteVotedPoll
//            self.viewModel.isMyPoll = isMyPoll
//        }
//        .store(in: &disposeBag)
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
