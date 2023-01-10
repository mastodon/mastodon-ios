// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

extension APIService {
    public func getHistory(
    forStatusID statusID: Mastodon.Entity.Status.ID,
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
}
