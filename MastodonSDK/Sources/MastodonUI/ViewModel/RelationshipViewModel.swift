//
//  RelationshipViewModel.swift
//  
//
//  Created by MainasuK on 2022-4-14.
//

import UIKit
import Combine
import MastodonAsset
import MastodonLocalization
import CoreDataStack

public enum RelationshipAction: Int, CaseIterable {
    case showReblogs
    case isMyself
    case followingBy
    case blockingBy
    case none       // set hide from UI
    case follow
    case request
    case pending
    case following
    case muting
    case blocked
    case blocking
    case suspended
    case edit
    case editing
    case updating

    public var option: RelationshipActionOptionSet {
        return RelationshipActionOptionSet(rawValue: 1 << rawValue)
    }
}

// construct option set on the enum for safe iterator
public struct RelationshipActionOptionSet: OptionSet {
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let isMyself = RelationshipAction.isMyself.option
    public static let followingBy = RelationshipAction.followingBy.option
    public static let blockingBy = RelationshipAction.blockingBy.option
    public static let none = RelationshipAction.none.option
    public static let follow = RelationshipAction.follow.option
    public static let request = RelationshipAction.request.option
    public static let pending = RelationshipAction.pending.option
    public static let following = RelationshipAction.following.option
    public static let muting = RelationshipAction.muting.option
    public static let blocked = RelationshipAction.blocked.option
    public static let blocking = RelationshipAction.blocking.option
    public static let suspended = RelationshipAction.suspended.option
    public static let edit = RelationshipAction.edit.option
    public static let editing = RelationshipAction.editing.option
    public static let updating = RelationshipAction.updating.option
    public static let showReblogs = RelationshipAction.showReblogs.option
    public static let editOptions: RelationshipActionOptionSet = [.edit, .editing, .updating]
    
    public func highPriorityAction(except: RelationshipActionOptionSet) -> RelationshipAction? {
        let set = subtracting(except)
        for action in RelationshipAction.allCases.reversed() where set.contains(action.option) {
            return action
        }
        
        return nil
    }

    public var title: String {
        guard let highPriorityAction = self.highPriorityAction(except: []) else {
            assertionFailure()
            return " "
        }
        switch highPriorityAction {
            case .isMyself: return ""
            case .followingBy: return " "
            case .blockingBy: return " "
            case .none: return " "
            case .follow: return L10n.Common.Controls.Friendship.follow
            case .request: return L10n.Common.Controls.Friendship.request
            case .pending: return L10n.Common.Controls.Friendship.pending
            case .following: return L10n.Common.Controls.Friendship.following
            case .muting: return L10n.Common.Controls.Friendship.muted
            case .blocked: return L10n.Common.Controls.Friendship.follow   // blocked by user   (deprecated)
            case .blocking: return L10n.Common.Controls.Friendship.blocked
            case .suspended: return L10n.Common.Controls.Friendship.follow
            case .edit: return L10n.Common.Controls.Friendship.editInfo
            case .editing: return L10n.Common.Controls.Actions.done
            case .updating: return " "
            case .showReblogs: return " "
        }
    }
}

@available(*, deprecated, message: "Replace with Mastodon.Entity.Relationship")
public final class RelationshipViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    public var userObserver: AnyCancellable?
    public var meObserver: AnyCancellable?
    
    // input
    @Published public var user: MastodonUser?
    @Published public var me: MastodonUser?
    public let relationshipUpdatePublisher = CurrentValueSubject<Void, Never>(Void())  // needs initial event
    
    // output
    @Published public var isMyself = false
    @Published public var optionSet: RelationshipActionOptionSet?
    
    @Published public var isFollowing = false
    @Published public var isFollowingBy = false
    @Published public var isMuting = false
    @Published public var showReblogs = false
    @Published public var isBlocking = false
    @Published public var isBlockingBy = false
    @Published public var isSuspended = false
    
    public init() {
        Publishers.CombineLatest3(
            $user,
            $me,
            relationshipUpdatePublisher
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] user, me, _ in
            guard let self = self else { return }
            self.update(user: user, me: me)
            
            guard let user = user, let me = me else {
                self.userObserver = nil
                self.meObserver = nil
                return
            }
            
            // do not modify object to prevent infinity loop
            self.userObserver = RelationshipViewModel.createObjectChangePublisher(user: user)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.relationshipUpdatePublisher.send()
                }
                
            self.meObserver = RelationshipViewModel.createObjectChangePublisher(user: me)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.relationshipUpdatePublisher.send()
                }
        }
        .store(in: &disposeBag)
    }
    
}

extension RelationshipViewModel {
    
    public static func createObjectChangePublisher(user: MastodonUser) -> AnyPublisher<Void, Never> {
        return ManagedObjectObserver
            .observe(object: user)
            .map { _ in Void() }
            .catch { error in
                return Just(Void())
            }
            .eraseToAnyPublisher()
    }
    
}

extension RelationshipViewModel {
    private func update(user: MastodonUser?, me: MastodonUser?) {
        guard let user = user,
              let me = me
        else {
            reset()
            return
        }
        
        let optionSet = RelationshipViewModel.optionSet(user: user, me: me)

        self.isMyself = optionSet.contains(.isMyself)
        self.isFollowingBy = optionSet.contains(.followingBy)
        self.isFollowing = optionSet.contains(.following)
        self.isMuting = optionSet.contains(.muting)
        self.isBlockingBy = optionSet.contains(.blockingBy)
        self.isBlocking = optionSet.contains(.blocking)
        self.isSuspended = optionSet.contains(.suspended)
        self.showReblogs = optionSet.contains(.showReblogs)

        self.optionSet = optionSet
    }
    
    private func reset() {
        isMyself = false
        isFollowingBy = false
        isFollowing = false
        isMuting = false
        isBlockingBy = false
        isBlocking = false
        optionSet = nil
        showReblogs = false
    }
}

extension RelationshipViewModel {

    public static func optionSet(user: MastodonUser, me: MastodonUser) -> RelationshipActionOptionSet {
        let isMyself = user.id == me.id && user.domain == me.domain
        guard !isMyself else {
            return [.isMyself, .edit]
        }
        
        let isProtected = user.locked
        let isFollowingBy = me.followingBy.contains(user)
        let isFollowing = user.followingBy.contains(me)
        let isPending = user.followRequestedBy.contains(me)
        let isMuting = user.mutingBy.contains(me)
        let isBlockingBy = me.blockingBy.contains(user)
        let isBlocking = user.blockingBy.contains(me)
        let isShowingReblogs = me.showingReblogsBy.contains(user)

        var optionSet: RelationshipActionOptionSet = [.follow]
        
        if isMyself {
            optionSet.insert(.isMyself)
        }
        
        if isProtected {
            optionSet.insert(.request)
        }
        
        if isFollowingBy {
            optionSet.insert(.followingBy)
        }
        
        if isFollowing {
            optionSet.insert(.following)
        }
        
        if isPending {
            optionSet.insert(.pending)
        }
        
        if isMuting {
            optionSet.insert(.muting)
        }
        
        if isBlockingBy {
            optionSet.insert(.blockingBy)
        }

        if isBlocking {
            optionSet.insert(.blocking)
        }
        
        if user.suspended {
            optionSet.insert(.suspended)
        }

        if isShowingReblogs {
            optionSet.insert(.showReblogs)
        }

        return optionSet
    }
}
