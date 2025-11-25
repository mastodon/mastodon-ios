//
//  APIService+AsyncRefresh.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 11/21/25.
//
import MastodonSDK

extension APIService {
    public func fetchAsyncRefreshUpdate(
        forAsyncRefreshID refreshID: String,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Entity.AsyncRefresh {
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.AsyncRefresh>, Error>
        do {
            let response = try await Mastodon.API.AsyncRefresh.updatedAsyncRefresh(
                domain: authenticationBox.domain,
                asyncRefreshID: refreshID,
                session: session,
                authorization: authenticationBox.userAuthorization,
            ).singleOutput()
            result = .success(response)
        } catch {
            result = .failure(error)
        }
        
        let response = try result.get()
        return response.value
    }
}
