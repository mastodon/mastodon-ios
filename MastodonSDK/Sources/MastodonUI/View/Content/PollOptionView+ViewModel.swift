//
//  PollOptionView+ViewModel.swift
//
//
//  Created by MainasuK on 2021-12-8.
//

import UIKit
import Combine
import CoreData
import MetaTextKit
import MastodonAsset
import MastodonCore

extension PollOptionView {
    
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        formatter.roundingMode = .down
        return formatter
    }()
    
    public final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()
        public var objects = Set<NSManagedObject>()
        
        let layoutDidUpdate = PassthroughSubject<Void, Never>()

        @Published public var authContext: AuthContext?

        @Published public var style: PollOptionView.Style?

        @Published public var content: String = ""          // for edit style
        
        @Published public var metaContent: MetaContent?     // for plain style
        @Published public var percentage: Double?
        
        @Published public var isExpire: Bool = false
        @Published public var isMultiple: Bool = false
        @Published public var isSelect: Bool? = false       // nil for server not return selection array
        @Published public var isPollVoted: Bool = false
        @Published public var isMyPoll: Bool = false
        @Published public var isReveal: Bool = false

        @Published public var selectState: SelectState = .none
        @Published public var voteState: VoteState = .hidden
        
        @Published public var roundedBackgroundViewColor: UIColor = .clear
        @Published public var primaryStripProgressViewTintColor: UIColor = Asset.Colors.brand.color.withAlphaComponent(0.8)
        @Published public var secondaryStripProgressViewTintColor: UIColor = Asset.Colors.brand.color.withAlphaComponent(0.5)
        
        @Published public var groupedAccessibilityLabel = ""
        
        init() {
            // selectState
            Publishers.CombineLatest3(
                $isSelect,
                $isExpire,
                $isPollVoted
            )
            .map { isSelect, isExpire, isPollVoted -> SelectState in
                if isSelect == true {
                    return .on
                } else if isExpire {
                    return .none
                } else if isPollVoted, isSelect == nil {
                    return .none
                } else {
                    return .off
                }
            }
            .assign(to: &$selectState)
            // voteState
            Publishers.CombineLatest3(
                $isReveal,
                $isSelect,
                $percentage
            )
            .map { isReveal, isSelect, percentage -> VoteState in
                guard isReveal else {
                    return .hidden
                }
                let oldPercentage = self.percentage
                let animated = oldPercentage != nil && percentage != nil
                
                return .reveal(voted: isSelect == true, percentage: percentage ?? 0, animating: animated)
            }
            .assign(to: &$voteState)
            // isReveal
            Publishers.CombineLatest3(
                $isExpire,
                $isPollVoted,
                $isMyPoll
            )
            .map { isExpire, isPollVoted, isMyPoll in
                return isExpire || isPollVoted || isMyPoll
            }
            .assign(to: &$isReveal)
            
            
        }
        
        public enum Corner: Hashable {
            case none
            case circle
            case radius(CGFloat)
        }
        
        public enum SelectState: Equatable, Hashable {
            case none
            case off
            case on
        }

        public enum VoteState: Equatable, Hashable {
            case hidden
            case reveal(voted: Bool, percentage: Double, animating: Bool)
        }
    }
}

extension PollOptionView.ViewModel {
    public func bind(view: PollOptionView) {
        // backgroundColor
        $roundedBackgroundViewColor
            .map { $0 as UIColor? }
            .assign(to: \.backgroundColor, on: view.roundedBackgroundView)
            .store(in: &disposeBag)
        // content
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: view.optionTextField)
            .receive(on: DispatchQueue.main)
            .map { _ in view.optionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
            .assign(to: &$content)
        // metaContent
        $metaContent
            .sink { metaContent in
                guard let metaContent = metaContent else {
                    view.optionTextField.text = ""
                    view.optionTextField.accessibilityLabel = ""
                    return
                }
                view.optionTextField.text = metaContent.string
                view.optionTextField.accessibilityLabel = metaContent.string
            }
            .store(in: &disposeBag)
        // selectState
        $selectState
            .sink { selectState in
                switch selectState {
                case .none:
                    view.checkmarkBackgroundView.isHidden = true
                    view.checkmarkImageView.isHidden = true
                case .off:
                    view.checkmarkBackgroundView.isHidden = false
                    view.checkmarkImageView.isHidden = true
                case .on:
                    view.checkmarkBackgroundView.isHidden = false
                    view.checkmarkImageView.isHidden = false
                }
            }
            .store(in: &disposeBag)
        // voteState
        $voteState
            .sink { [weak self] voteState in
                guard let self = self else { return }
                switch voteState {
                case .hidden:
                    view.optionPercentageLabel.isHidden = true
                    view.voteProgressStripView.isHidden = true
                    view.voteProgressStripView.setProgress(0.0, animated: false)
                case .reveal(let voted, let percentage, let animating):
                    view.optionPercentageLabel.isHidden = false
                    view.optionPercentageLabel.text = String(Int(100 * percentage)) + "%"
                    view.voteProgressStripView.isHidden = false
                    view.voteProgressStripView.tintColor = voted ? self.primaryStripProgressViewTintColor : self.secondaryStripProgressViewTintColor
                    view.voteProgressStripView.setProgress(CGFloat(percentage), animated: animating)
                }
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            $voteState,
            layoutDidUpdate
        )
        .sink { voteState, _ in
            guard case .plain = view.style else { return }
            
            view.layoutIfNeeded()
            
            switch voteState {
            case .hidden:
                view.optionTextField.textColor = Asset.Colors.Label.primary.color
                view.optionTextField.layer.removeShadow()
            case .reveal(_, let percentage, _):
                if CGFloat(percentage) * view.roundedBackgroundView.frame.width > view.optionLabelMiddlePaddingView.frame.minX {
                    view.optionTextField.textColor = .white
                    view.optionTextField.layer.setupShadow(x: 0, y: 0, blur: 4, spread: 0)
                } else {
                    view.optionTextField.textColor = Asset.Colors.Label.primary.color
                    view.optionTextField.layer.removeShadow()
                }

                if CGFloat(percentage) * view.roundedBackgroundView.frame.width > view.optionLabelMiddlePaddingView.frame.maxX {
                    view.optionPercentageLabel.textColor = .white
                    view.optionPercentageLabel.layer.setupShadow(x: 0, y: 0, blur: 4, spread: 0)
                } else {
                    view.optionPercentageLabel.textColor = Asset.Colors.Label.primary.color
                    view.optionPercentageLabel.layer.removeShadow()
                }
            }
        }
        .store(in: &disposeBag)
        
        bindAccessibility(view: view)
    }
    
    private func bindAccessibility(view: PollOptionView) {
        $selectState
            .sink { selectState in
                switch selectState {
                case .on:
                    view.accessibilityTraits.insert(.selected)
                default:
                    view.accessibilityTraits.remove(.selected)
                }
            }
            .store(in: &disposeBag)
    }
}
