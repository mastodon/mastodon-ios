//
//  Mastodon+API+PaginationLinks.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 11/17/25.
//

import Foundation
import Combine

extension Mastodon.API.Timeline {
    public static func statuses(
        session: URLSession,
        url: URL,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error>  {
        let request = Mastodon.API.get(
            fromPrecompiledUrl: url,
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("fetch statuses from precompiled url")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func accounts(
        session: URLSession,
        url: URL,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> {
        let request = Mastodon.API.get(
            fromPrecompiledUrl: url,
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("fetch accounts from precompiled url")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Account].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func hashtags(
        session: URLSession,
        url: URL,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error>  {
        let request = Mastodon.API.get(
            fromPrecompiledUrl: url,
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("fetch hashtags from precompiled url")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Tag].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func groupedNotifications(
        session: URLSession,
        url: URL,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.GroupedNotificationsResults>, Error>  {
        let request = Mastodon.API.get(
            fromPrecompiledUrl: url,
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("fetch grouped notifications from precompiled url")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.GroupedNotificationsResults.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func notificationRequests(
        session: URLSession,
        url: URL,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.NotificationRequest]>, Error> {
        let request = Mastodon.API.get(
            fromPrecompiledUrl: url,
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("fetch notification requests from precompiled url")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.NotificationRequest].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func ungroupedNotifications(
        session: URLSession,
        url: URL,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Notification]>, Error>  {
        let request = Mastodon.API.get(
            fromPrecompiledUrl: url,
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("fetch ungrouped notifications from precompiled url")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Notification].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}
