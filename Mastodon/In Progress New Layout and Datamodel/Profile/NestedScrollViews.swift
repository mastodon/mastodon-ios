// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct NestedScrollView: ViewModifier {
    @Environment(NestedScrollInteractionViewModel.self) var viewModel
    let nestedRole: NestedScrollviewRole
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .scrollDisabled(nestedRole == .inner ? viewModel.innerScrollDisabled : false)
                .onScrollGeometryChange(for: ScrollInteractionState.self) { scrollGeometry in
                    let contentHeight = scrollGeometry.contentSize.height
                    let snapshot = ScrollSnapshot(yOffset: scrollGeometry.contentOffset.y, contentHeight: contentHeight)
                    switch nestedRole {
                    case .outer:
                        let contentSizeWithoutInnerScrollview = contentHeight - geo.size.height
                        let maxOffset = contentSizeWithoutInnerScrollview - geo.safeAreaInsets.top
                        return viewModel.updateOuterScroll(newSnapshot: snapshot, maxOffset: maxOffset)
                    case .inner:
                        let maxOffset = contentHeight - geo.size.height // the real value doesn't matter much here because we don't do anything when reaching the bottom
                        return viewModel.updateInnerScroll(newSnapshot: snapshot, maxOffset: maxOffset)
                    case .notNested:
                        return ScrollInteractionState(previousState: nil, currentSnapshot: snapshot, scrollPhase: nil, maxOffset: 0)
                    }
                } action: { _, newScroll in
                    switch (nestedRole, newScroll) {
                    case (.notNested, _):
                        break
                    case (_, .idle), (_, .animating):
                        break
                        
                    // OUTER
                    case (.outer, .draggingTowardsContentTop):
                        if !viewModel.innerScrollDisabled {
                            viewModel.innerScrollDisabled = true // this handles the case that you scrolled just exactly enough to enable inner scrolling, then changed your mind and used the inner view to pull down and start to show some of the outer scroll contents again
                        }
                    case (.outer, .coastingTowardsContentTop), (.outer, .bouncingOffTop):
                        break
                    case (.outer, .draggingTowardsContentBottom(_, let hasReachedBottom)), (.outer, .coastingTowardsContentBottom(_, let hasReachedBottom)):
                        if hasReachedBottom && viewModel.innerScrollDisabled {
                            viewModel.innerScrollDisabled = false
                        }
                    case (.outer, .bouncingOffBottom):
                        if viewModel.innerScrollDisabled {
                            viewModel.innerScrollDisabled = false
                        }
                        
                    // INNER
                    case (.inner, .draggingTowardsContentTop(_, let hasReachedTop)), (.inner, .coastingTowardsContentTop(_, let hasReachedTop)):
                        if hasReachedTop && !viewModel.innerScrollDisabled {
                            viewModel.innerScrollDisabled = true
                        }
                    case (.inner, .bouncingOffTop):
                        if !viewModel.innerScrollDisabled {
                            viewModel.innerScrollDisabled = true
                        }
                    case (.inner, .draggingTowardsContentBottom), (.inner, .coastingTowardsContentBottom), (.inner, .bouncingOffBottom):
                        break
                    }
                }
                .onScrollPhaseChange { oldPhase, newPhase in
                    switch nestedRole {
                    case .outer:
                        viewModel.updateOuterScrollPhase(newPhase)
                    case .inner:
                        viewModel.updateInnerScrollPhase(newPhase)
                    case .notNested:
                        break
                    }
                }
        }
    }
}

enum NestedScrollviewRole {
    case outer
    case inner
    case notNested
}

extension View {
    func nestedScrollview(
        _ nestedRole: NestedScrollviewRole
    ) -> some View {
        modifier(
            NestedScrollView(nestedRole: nestedRole)
        )
    }
}

struct ConditionallyRefreshable: ViewModifier {
    let pullToRefreshAction: (() async -> ())?
    
    func body(content: Content) -> some View {
        if let pullToRefreshAction {
            content
                .refreshable {
                    await pullToRefreshAction()
                }
        } else {
            content
        }
    }
}

extension View {
    func conditionallyRefreshable(_ pullToRefresh: (() async -> ())?) -> some View {
        modifier (
            ConditionallyRefreshable(pullToRefreshAction: pullToRefresh)
        )
    }
}


enum ScrollDirection {
    case unknown
    case stationary
    case towardsContentBottom
    case towardsContentTop
    
    var name: String {
        switch self {
        case .unknown: "unknown"
        case .stationary: "stationary"
        case .towardsContentBottom: "towards BOTTOM"
        case .towardsContentTop: "towards TOP"
        }
    }
    
    static func fromOldOffset(_ oldOffset: CGFloat?, newOffset: CGFloat) -> ScrollDirection {
        guard let oldOffset else { return .unknown }
        let diff = newOffset - oldOffset
        switch diff {
        case ..<0:
            return .towardsContentTop
        case 0:
            return .stationary
        default:
            return .towardsContentBottom
        }
        
    }
}

struct ScrollSnapshot: Equatable {
    let yOffset: CGFloat
    let contentHeight: CGFloat
}

enum ScrollInteractionState: Equatable {
    case idle(ScrollSnapshot)
    case animating(ScrollSnapshot)
    case draggingTowardsContentTop(ScrollSnapshot, hasReachedTop: Bool)
    case coastingTowardsContentTop(ScrollSnapshot, hasReachedTop: Bool)
    case bouncingOffTop(ScrollSnapshot)
    case draggingTowardsContentBottom(ScrollSnapshot, hasReachedBottom: Bool)
    case coastingTowardsContentBottom(ScrollSnapshot, hasReachedBottom: Bool)
    case bouncingOffBottom(ScrollSnapshot)
    
    init(previousState: ScrollInteractionState?, currentSnapshot: ScrollSnapshot, scrollPhase: ScrollPhase?, maxOffset: CGFloat) {
        guard let scrollPhase, let previousState else { self = .idle(currentSnapshot); return }
        
        switch scrollPhase {
        case .idle, .tracking:
            self = .idle(currentSnapshot)
        case .interacting:
            let direction = ScrollDirection.fromOldOffset(previousState.yOffset, newOffset: currentSnapshot.yOffset)
            switch direction {
            case .stationary, .unknown:
                switch previousState {
                case .idle, .animating, .coastingTowardsContentTop, .bouncingOffTop, .coastingTowardsContentBottom, .bouncingOffBottom:
                    self = .idle(currentSnapshot)
                case .draggingTowardsContentTop:
                    self = .draggingTowardsContentTop(currentSnapshot, hasReachedTop: currentSnapshot.yOffset <= 0)
                case .draggingTowardsContentBottom:
                    self = .draggingTowardsContentBottom(currentSnapshot, hasReachedBottom: currentSnapshot.yOffset >= maxOffset)
                }
            case .towardsContentTop:
                self = .draggingTowardsContentTop(currentSnapshot, hasReachedTop: currentSnapshot.yOffset <= 0)
            case .towardsContentBottom:
                self = .draggingTowardsContentBottom(currentSnapshot, hasReachedBottom: currentSnapshot.yOffset >= maxOffset)
            }
        case .animating:
            self = .animating(currentSnapshot)
        case .decelerating:
            let direction = ScrollDirection.fromOldOffset(previousState.yOffset, newOffset: currentSnapshot.yOffset)
            switch direction {
            case .stationary, .unknown:
                switch previousState {
                case .idle, .animating, .bouncingOffTop, .bouncingOffBottom:
                    self = .idle(currentSnapshot)
                case .draggingTowardsContentTop, .coastingTowardsContentTop:
                    self = .coastingTowardsContentTop(currentSnapshot, hasReachedTop: currentSnapshot.yOffset <= 0)
                case .draggingTowardsContentBottom, .coastingTowardsContentBottom:
                    self = .coastingTowardsContentBottom(currentSnapshot, hasReachedBottom: currentSnapshot.yOffset >= maxOffset)
                }
            case .towardsContentTop:
                switch previousState {
                case .coastingTowardsContentTop, .draggingTowardsContentTop:
                    self = .coastingTowardsContentTop(currentSnapshot, hasReachedTop: currentSnapshot.yOffset <= 0)
                case .coastingTowardsContentBottom, .draggingTowardsContentBottom, .bouncingOffBottom:
                    self = .bouncingOffBottom(currentSnapshot)
                case .idle, .animating, .bouncingOffTop:
                    assertionFailure("unexpected transition to decelerating scroll phase")
                    self = .coastingTowardsContentTop(currentSnapshot, hasReachedTop: currentSnapshot.yOffset <= 0)
                }
            case .towardsContentBottom:
                switch previousState {
                case .coastingTowardsContentBottom, .draggingTowardsContentBottom:
                    self = .coastingTowardsContentBottom(currentSnapshot, hasReachedBottom: currentSnapshot.yOffset >= maxOffset)
                case .coastingTowardsContentTop, .draggingTowardsContentTop, .bouncingOffTop:
                    self = .bouncingOffTop(currentSnapshot)
                case .idle, .animating:
                    assertionFailure("unexpected transition to decelerating scroll phase")
                    self = .coastingTowardsContentBottom(currentSnapshot, hasReachedBottom: currentSnapshot.yOffset >= maxOffset)
                case .bouncingOffBottom:
                    self = .coastingTowardsContentBottom(currentSnapshot, hasReachedBottom: currentSnapshot.yOffset >= maxOffset)
                }
            }
        }
    }
    
    var yOffset: CGFloat {
        switch self {
        case .animating(let snap), .bouncingOffBottom(let snap), .bouncingOffTop(let snap), .coastingTowardsContentBottom(let snap, _), .coastingTowardsContentTop(let snap, _), .draggingTowardsContentBottom(let snap, _), .draggingTowardsContentTop(let snap, _), .idle(let snap):
            return snap.yOffset
        }
    }
    
    static func ==(lhs: ScrollInteractionState, rhs: ScrollInteractionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle(let lSnap), .idle(let rSnap)):
            lSnap == rSnap
        case (.animating, .animating):
            true
        case (.draggingTowardsContentTop(_, let lTop), .draggingTowardsContentTop(_, let rTop)):
            lTop == rTop
        case (.coastingTowardsContentTop(_, let lTop), .coastingTowardsContentTop(_, let rTop)):
            lTop == rTop
        case (.bouncingOffTop, .bouncingOffTop):
            true
        case (.draggingTowardsContentBottom(_, let lBottom), .draggingTowardsContentBottom(_, let rBottom)):
            lBottom == rBottom
        case (.coastingTowardsContentBottom(_, let lBottom), .coastingTowardsContentBottom(_, let rBottom)):
            lBottom == rBottom
        case (.bouncingOffBottom, .bouncingOffBottom):
            true
        default:
            false
        }
    }
}

@Observable class NestedScrollInteractionViewModel {
    @ObservationIgnored private var outerScrollState: ScrollInteractionState?
    @ObservationIgnored private var outerScrollPhase: ScrollPhase = .idle
    @ObservationIgnored private var innerScrollState: ScrollInteractionState?
    @ObservationIgnored private var innerScrollPhase: ScrollPhase = .idle
    
    var innerScrollDisabled: Bool = true
    
    func updateOuterScroll(newSnapshot: ScrollSnapshot, maxOffset: CGFloat) -> ScrollInteractionState {
        let newScrollInteractionState = ScrollInteractionState(previousState: outerScrollState, currentSnapshot: newSnapshot, scrollPhase: outerScrollPhase, maxOffset: maxOffset)
        outerScrollState = newScrollInteractionState
        return newScrollInteractionState
    }
    
    func updateOuterScrollPhase(_ newScrollPhase: ScrollPhase) {
        outerScrollPhase = newScrollPhase
    }
    
    func updateInnerScroll(newSnapshot: ScrollSnapshot, maxOffset: CGFloat) -> ScrollInteractionState {
        let newScrollInteractionState = ScrollInteractionState(previousState: innerScrollState, currentSnapshot: newSnapshot, scrollPhase: innerScrollPhase, maxOffset: maxOffset)
        innerScrollState = newScrollInteractionState
        return newScrollInteractionState
    }
    
    func updateInnerScrollPhase(_ newScrollPhase: ScrollPhase) {
        innerScrollPhase = newScrollPhase
    }
}
