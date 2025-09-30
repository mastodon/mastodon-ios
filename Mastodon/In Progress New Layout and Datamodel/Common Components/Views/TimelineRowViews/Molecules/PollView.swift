// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonSDK
import MastodonLocalization
import MastodonCore

struct PollView: View {
    @StateObject var viewModel: PollViewModel
    let contentWidth: CGFloat
    @ScaledMetric var percentLabelWidth: CGFloat = 55
    
    var body: some View {
        VStack(alignment: .leading, spacing: standardPadding) {
            
            // OPTIONS
            ForEach(viewModel.options, id: \.self.id) { option in
                optionRow(option, index: option.index)
            }
            
            // INFO
            infoLine
            
            // ACTION BUTTONS
            let vote = voteButton
            let viewResults = viewResultsButton
            if vote != nil || viewResults != nil {
                HStack {
                    if let vote {
                        Button {
                            viewModel.submitVote()
                        } label: {
                            buttonView(vote)
                        }
                        .disabled(vote.isDisabled)
                        .buttonStyle(.borderless)
                        .accessibilityHidden(true)
                    } else {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                    
                    if let viewResults {
                        Button() {
                            viewModel.viewingResults = !viewModel.viewingResults
                        } label: {
                            buttonView(viewResults)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityHidden(true)
                    }
                }
                .fontWeight(.semibold)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.Scene.Notification.Headers.poll)
        .accessibilityHint(a11yVoteHint)
        .accessibilityActions {
            if let vote = voteButton {
                if !vote.isDisabled {
                    Button {
                        viewModel.submitVote()
                    } label: {
                        buttonView(vote)
                    }
                }
            }
            if let viewResults = viewResultsButton {
                Button() {
                    viewModel.viewingResults = !viewModel.viewingResults
                } label: {
                    buttonView(viewResults)
                }
            }
        }
    }
    
    var a11yVoteHint: String {
        switch viewModel.votingState {
        case .selecting(let selectionState):
            switch selectionState {
            case .multiSelect(let selected):
                if selected.count == 0 {
                    return L10n.Common.Controls.Status.Poll.multiselectA11yHint
                }
            case .singleSelect(let selected):
                if selected == nil {
                    return L10n.Common.Controls.Status.Poll.singleSelectA11yHint
                }
            }
        default:
            return ""
        }
        return ""
    }
    
    @ViewBuilder func optionRow(_ option: PollViewModel.Option, index: Int) -> some View {
        let iVotedForThisOption = viewModel.votingState.selectionState?.hasSelected(optionIndex: index) ?? false
        let optionResults = viewModel.results(forOption: index)
        
        Button {
            viewModel.selectOption(atIndex: index)
        } label: {
            ZStack(alignment: .leading) {
                
                // Fill proportional to vote percentage, if viewing results
                if viewModel.viewingResults {
                    Rectangle()
                        .fill(resultFillColor(isSelected: iVotedForThisOption))
                        .frame(width: max(1, (contentWidth - percentLabelWidth - PollPadding.optionPadding) * optionResults))
                        .frame(minHeight: 44, maxHeight: .infinity)
                } else if iVotedForThisOption {
                    Rectangle()
                        .fill(resultFillColor(isSelected: true))
                        .frame(width: contentWidth)
                        .frame(minHeight: 44, maxHeight: .infinity)
                }
                
                HStack(spacing: 0) {
                    // The selection button image
                    if !viewModel.viewingResults {
                        Image(systemName: selectionImageNameForOption(at: index))
                            .foregroundStyle(iVotedForThisOption ? Asset.Colors.Brand.blurple.swiftUIColor : .secondary)
                        Spacer()
                            .frame(width: standardPadding)
                    }
                    
                    MastodonContentView.header(html: option.text, emojis: option.emojis, style: .pollOption)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if viewModel.viewingResults {
                        Spacer()
                        Divider()
                        Text(String(Int(round(100 * optionResults))) + "%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(EdgeInsets(top: 0, leading: PollPadding.optionPadding, bottom: 0, trailing: 0))
                            .frame(width: percentLabelWidth, alignment: .trailing)
                    }
                }
                .padding(PollPadding.optionPadding)
                
                RoundedRectangle(cornerRadius: CornerRadius.standard)
                    .fill(.clear)
                    .strokeBorder(.separator)
            }
            .frame(width: contentWidth)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        }
        .disabled(viewModel.viewingResults)
        .buttonStyle(.borderless)
    }
    
    @ViewBuilder var infoLine: some View {
        let voterCount = viewModel.voterCount
        let timeLeftDescription = viewModel.timeLeftDescription
        
        let textElements: [String] =  {
           var elements = [String]()
            if let voterCount {
                elements.append(L10n.Plural.Count.vote(voterCount))
            }
            if let timeLeftDescription {
                elements.append(timeLeftDescription)
            }
            if viewModel.isMultiselect {
                elements.append(L10n.Common.Controls.Status.Poll.chooseOneOrMore)
            }
            return elements
        }()
        
        HStack(spacing: tinySpacing) {
                Text(textElements.joined(separator: " · "))
                    .fixedSize()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(EdgeInsets(top: 0, leading: PollPadding.optionPadding, bottom: 0, trailing: PollPadding.optionPadding))
    }
    
    func resultFillColor(isSelected: Bool) -> Color {
        let color = isSelected ? Asset.Colors.Brand.lightBlurple.swiftUIColor : .secondary
        return color.opacity(0.5)
    }
    
    func selectionImageNameForOption(at index: Int) -> String {
        let thisOptionIsSelected = viewModel.votingState.selectionState?.hasSelected(optionIndex: index) == true
        if viewModel.isMultiselect {
            if thisOptionIsSelected {
                return "checkmark.circle.fill"
            } else {
                return "circle"
            }
        } else {
            if thisOptionIsSelected {
                return "inset.filled.circle"
            } else {
                return "circle"
            }
        }
    }
    
    enum PollActionButtonType: Equatable {
        case vote(enabled: Bool)
        case submitting
        case voted
        case showResults
        case hideResults
        
        var isDisabled: Bool {
            switch self {
            case .vote(let enabled):
                return !enabled
            case .submitting, .voted:
                return true
            case .showResults, .hideResults:
                return false
            }
        }
        
        var text: String {
            switch self {
            case .vote(let enabled):
                return L10n.Common.Controls.Status.Poll.vote
            case .submitting:
                return ""
            case .voted:
                return L10n.Common.Controls.Status.Poll.voted
            case .showResults:
                return L10n.Common.Controls.Status.Poll.seeResults
            case .hideResults:
                return L10n.Common.Controls.Status.Poll.hideResults
            }
        }
        
        var fillColor: Color {
            switch self {
            case .vote, .voted, .submitting:
                primaryButtonFill(disabled: isDisabled)
            case .showResults, .hideResults:
                secondaryButtonFill
            }
        }
        
        var textColor: Color {
            switch self {
            case .vote, .voted, .submitting:
                primaryButtonTextColor(disabled: isDisabled)
            case .showResults, .hideResults:
                .primary
            }
        }
        
        func primaryButtonFill(disabled: Bool) -> Color {
            disabled ? .secondary.opacity(0.5) : Asset.Colors.Brand.darkBlurple.swiftUIColor
        }
        
        func primaryButtonTextColor(disabled: Bool) -> Color {
            disabled ? .gray : .white
        }
        
        var secondaryButtonFill: Color {
            Asset.Colors.Brand.lightBlurple.swiftUIColor.opacity(0.5)
        }
    }
    
    var voteButton: PollActionButtonType? {
        switch viewModel.votingState {
        case .isMyPoll:
            return nil
        case .pollClosed(let myVote):
            if myVote == nil {
                return nil
            } else {
                return .voted
            }
        case .selecting(let selectionState), .error(let selectionState, _):
            return viewModel.viewingResults ? nil : .vote(enabled: selectionState.hasSomethingSelected)
        case .submittingVote(let selectionState):
            return .submitting
        case .didVote(let selectionState):
            return .voted
        }
    }
    
    var viewResultsButton: PollActionButtonType? {
        switch viewModel.votingState {
        case .isMyPoll:
            return nil
        case .pollClosed:
            return nil
        case .selecting(let selectionState), .submittingVote(let selectionState):
            return viewModel.viewingResults ? .hideResults : .showResults
        case .didVote(let selectionState):
            return nil
        case .error(let selectionState, let error):
            return .vote(enabled: selectionState.hasSomethingSelected)
        }
    }
    
    @ViewBuilder func buttonView(_ actionButtonType: PollActionButtonType) -> some View {
        ZStack {
            Text(actionButtonType.text)
                .frame(maxWidth: .infinity)
                .foregroundStyle(actionButtonType.textColor)
                .padding(EdgeInsets(top: ButtonPadding.vertical, leading: ButtonPadding.capsuleHorizontal, bottom: ButtonPadding.vertical, trailing: ButtonPadding.capsuleHorizontal))
                .background {
                    Capsule()
                        .fill(actionButtonType.fillColor)
                        .frame(height: 34)
                }
            
            if actionButtonType == .submitting {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }
}

class PollViewModel: ObservableObject {
 
    enum SelectionState {
        case multiSelect(selected: [Int])
        case singleSelect(selected: Int?)
    }
 
    enum VotingState {
        case isMyPoll(isClosed: Bool)  // not allowed to vote
        case pollClosed(myVote: SelectionState?) // no new votes allowed
        case selecting(SelectionState)
        case submittingVote(SelectionState)
        case didVote(SelectionState)
        case error(SelectionState, Error)
    }
    
    let options: [Option]
    @Published var votingState: VotingState
    @Published var viewingResults: Bool
    
    private var entity: Mastodon.Entity.Poll
    private let containingPostID: Mastodon.Entity.Status.ID
    private let optionTranslations: [String]?
    private let actionHandler: MastodonPostMenuActionHandler
    
    init(pollEntity: Mastodon.Entity.Poll, emojis: [Mastodon.Entity.Emoji]?, optionTranslations: [String]?, containingPostID: Mastodon.Entity.Status.ID, actionHandler: MastodonPostMenuActionHandler) {
        entity = pollEntity
        self.containingPostID = containingPostID
        self.optionTranslations = optionTranslations
        self.actionHandler = actionHandler
        options = pollEntity.options.enumerated().map { (index, entityOption) in
            Option(index: index, text: optionTranslations?[index] ?? entityOption.title, emojis: emojis ?? [])
        }

        let votingState = VotingState.fromEntity(pollEntity)
        viewingResults = !votingState.canVote
        self.votingState = votingState
    }
    
    func submitVote() {
        if case let .selecting(selectionState) = votingState, !selectionState.selectedIndexes.isEmpty {
            votingState = .submittingVote(selectionState)
            Task { @MainActor in
                do {
                    let updatedPoll = try await actionHandler.vote(poll: entity, choices: selectionState.selectedIndexes, containingPostID: containingPostID)
                    entity = updatedPoll
                    votingState = VotingState.fromEntity(updatedPoll)
                    viewingResults = true
                } catch {
                    votingState = .error(selectionState, error)
                }
            }
        }
    }
    
    var isMultiselect: Bool {
        return entity.multiple
    }
    
    var voterCount: Int? {
        return entity.votersCount ?? 0
    }
    
    var timeLeftDescription: String? {
        if entity.expired {
            return L10n.Common.Controls.Status.Poll.closed
        } else {
            return entity.expiresAt?.localizedTimeLeft()
        }
    }
    
    func results(forOption index: Int) -> CGFloat {
        let option = entity.options[index]
        guard let optionVotes = option.votesCount, let voterCount = entity.votersCount, voterCount > 0 else { return 0 }
        return CGFloat(optionVotes) / CGFloat(voterCount)
    }
    
    func selectOption(atIndex index: Int) {
        if case let .selecting(currentSelection) = votingState {
            let newSelection: SelectionState
            switch currentSelection {
            case .multiSelect(let selected):
                if selected.contains(index) {
                    newSelection = .multiSelect(selected: selected.filter { index != $0 })
                } else {
                    newSelection = .multiSelect(selected: selected + [index])
                }
            case .singleSelect(let selected):
                newSelection = .singleSelect(selected: index)
            }
            
            votingState = .selecting(newSelection)
        }
    }
    
    struct Option: Identifiable {
        let index: Int
        let text: String
        let emojis: [Mastodon.Entity.Emoji]
        
        var id: Int {
            return index
        }
    }
}

extension PollViewModel.VotingState {
    static func fromEntity(_ entity: Mastodon.Entity.Poll) -> Self {
        let pollIsClosed = entity.expired
        
        // MY POLL
        if entity.voted == true && (entity.ownVotes == nil || entity.ownVotes!.isEmpty) {
            // this combination seems to indicate that this is my own poll
            return .isMyPoll(isClosed: pollIsClosed)
        }
        
        let myVotes: PollViewModel.SelectionState = {
            if entity.multiple {
                return .multiSelect(selected: entity.ownVotes ?? [])
            } else {
                return .singleSelect(selected: entity.ownVotes?.first)
            }
        }()
        
        // POLL IS CLOSED
        if pollIsClosed {
            return .pollClosed(myVote: myVotes.hasSomethingSelected ? myVotes : nil)
        }
        
        // DID VOTE or SELECTING  (SUBMITTING VOTE and ERROR cannot be derived from a poll entity)
        if myVotes.hasSomethingSelected {
            return .didVote(myVotes)
        } else {
            return .selecting(myVotes)
        }
    }
    
    var canVote: Bool {
        switch self {
        case .didVote, .isMyPoll, .pollClosed:
            return false
        case .error, .selecting, .submittingVote:
            return true
        }
    }
    
    var selectionState: PollViewModel.SelectionState? {
        switch self {
        case .isMyPoll:
            return nil
        case .didVote(let selection), .error(let selection, _), .selecting(let selection), .submittingVote(let selection):
            return selection
        case .pollClosed(let selection):
            return selection
        }
    }
}

extension PollViewModel.SelectionState {
    var hasSomethingSelected: Bool {
        switch self {
        case .multiSelect(let selected):
            return !selected.isEmpty
        case .singleSelect(let selected):
            return selected != nil
        }
    }
    
    var selectedIndexes: [Int] {
        switch self {
        case .multiSelect(let selected):
            return selected
        case .singleSelect(let selected):
            guard let selected else { return [] }
            return [selected]
        }
    }
    
    func hasSelected(optionIndex: Int) -> Bool {
        selectedIndexes.contains(optionIndex)
    }
}
