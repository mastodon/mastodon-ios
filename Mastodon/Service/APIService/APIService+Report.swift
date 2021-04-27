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
 
    func report(
        domain: String,
        query: Mastodon.API.Reports.FileReportQuery,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Bool>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Reports.fileReport(session: session, domain: domain, query: query, authorization: authorization)
    }
}
