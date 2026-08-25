//
//  UnreadNotificationCounts.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 8/25/26.
//
import SwiftUI
import Combine

@MainActor
@Observable public final class UnreadNotificationCounts {
    public static let shared = UnreadNotificationCounts()
    
    private var loggedInUsersSubscription: AnyCancellable?
    
    private var countsByUser: [String : Int] = [:]
    
    private init() {
        refreshCounts()
        loggedInUsersSubscription = AuthenticationServiceProvider.shared.$mastodonAuthenticationBoxes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshCounts()
            }
    }
    
    public func unreadCount(for user: UserIdentifier) -> Int {
        countsByUser[user.globallyUniqueUserIdentifier] ?? 0
    }
    
    public func setUnreadCount(_ count: Int, for authentication: MastodonAuthentication) {
        UserDefaults.shared.setNotificationCount(count, rawAccessToken: authentication.userAccessToken)
        refreshCounts()
    }
    
    public func incrementUnreadCount(rawAccessToken: String) {
        UserDefaults.shared.incrementNotificationCount(rawAccessToken: rawAccessToken)
        refreshCounts()
    }
    
    public var combinedUnreadCountForAllUsers: Int {
        countsByUser.values.reduce(0, +)
    }
    
    public func refreshCounts() {
        countsByUser = AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.reduce(into: [:], { previousResult, box in
            previousResult[box.globallyUniqueUserIdentifier] = UserDefaults.shared.notificationCount(rawAccessToken: box.authentication.userAccessToken)
        })
    }
}
