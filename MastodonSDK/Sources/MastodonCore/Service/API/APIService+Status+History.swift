// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK
import CoreDataStack

extension APIService {

    public func getStatusSource(
        forStatusID statusID: Status.ID,
        authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Response.Content<Mastodon.Entity.StatusSource> {
            let domain = authenticationBox.domain
            let authorization = authenticationBox.userAuthorization

            let response = try await Mastodon.API.Statuses.statusSource(
                forStatusID: statusID,
                session: session,
                domain: domain,
                authorization: authorization).singleOutput()

            return response
        }

    public func getHistory(
        forStatusID statusID: Status.ID,
        authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Response.Content<[Mastodon.Entity.StatusEdit]> {
            let domain = authenticationBox.domain
            let authorization = authenticationBox.userAuthorization

            let response = try await Mastodon.API.Statuses.editHistory(
                forStatusID: statusID,
                session: session,
                domain: domain,
                authorization: authorization).singleOutput()

            return response
        }
    
    public func publishStatusEdit(
        forStatusID statusID: Status.ID,
        editStatusQuery: Mastodon.API.Statuses.EditStatusQuery,
        authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
            let domain = authenticationBox.domain
            let authorization = authenticationBox.userAuthorization
            
            let response = try await Mastodon.API.Statuses.editStatus(
                forStatusID: statusID,
                editStatusQuery: editStatusQuery,
                session: session,
                domain: domain,
                authorization: authorization).singleOutput()

            return response
        }
}
