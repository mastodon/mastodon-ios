//
//  Mastodon+API+Account+Email.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 9/30/26.
//

import Foundation

extension Mastodon.API.Account {
    static func emailConfirmationsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("emails/confirmations")
    }
    
    /// Resend a new confirmation email. If an email is provided, updates the unconfirmed user’s email before resending the confirmation email.
    /// Returns: Empty
    /// OAuth: User token issued to the client that created the unconfirmed user
    /// Version history:
    /// 3.4.0 - added
    /// # Reference
    /// [Document](https://docs.joinmastodon.org/methods/emails/)
    public static func resendConfirmationEmail(
        session: URLSession,
        domain: String,
        email: String? = nil,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws {
        let request = Mastodon.API.post(
            url: emailConfirmationsEndpointURL(domain: domain),
            query: ResendConfirmationEmailQuery(email: email),
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("resend confirmation email")
        let (data, response) = try await session.data(for: request)
        try Mastodon.API.decodeEmpty(from: data, response: response)
    }
    
    public struct ResendConfirmationEmailQuery: Codable, PostQuery {
        // this email will overwrite the email an unconfirmed account was created with
        public let email: String?
        
        public init(email: String? = nil) {
            self.email = email
        }
    }
}
