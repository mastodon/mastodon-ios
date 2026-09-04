// Copyright © 2026 Mastodon gGmbH. All rights reserved.
import MastodonCore
import AuthenticationServices
import SwiftUI

@MainActor
enum ReauthorizeLogin {
    static func launchReauthorization(withDomain domain: String, session: WebAuthenticationSession) async throws {
        let application = try await APIService.shared.createApplication(domain: domain)
        guard let authenticateInfo = AuthenticationViewModel.AuthenticateInfo(domain: domain, application: application) else { throw AuthenticationViewModel.AuthenticationError.badCredentials }
        
        let callbackUrl = try await session.authenticate(
            using: authenticateInfo.authorizeURL,
            callbackURLScheme: APIService.callbackURLScheme,
            preferredBrowserSession: .ephemeral)
        
        guard let code = URLComponents(
            url: callbackUrl,
            resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
        else {
            throw AuthenticationViewModel.AuthenticationError.badCredentials
        }
        
        let token = try await APIService.shared.userAccessToken(
            domain: authenticateInfo.domain,
            clientID: authenticateInfo.clientID,
            clientSecret: authenticateInfo.clientSecret,
            redirectURI: authenticateInfo.redirectURI,
            code: code
        )
        
        _ = try await AuthenticationViewModel.verifyAndActivateAuthentication(info: authenticateInfo, userToken: token)
    }
}
