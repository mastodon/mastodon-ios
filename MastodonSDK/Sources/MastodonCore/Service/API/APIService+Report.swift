//
//  APIService+Report.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/19.
//

import Foundation
import MastodonSDK
import Combine

extension APIService {
 
    public func report(
        query: Mastodon.API.Reports.FileReportQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Bool> {
        let response = try await Mastodon.API.Reports.fileReport(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }
    
}
