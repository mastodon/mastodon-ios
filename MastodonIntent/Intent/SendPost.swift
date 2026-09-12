// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import Foundation
import AppIntents
import MastodonSDK
import MastodonCore

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct SendPost: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SendPostIntent"

    static var title: LocalizedStringResource = "Post on Mastodon"
    static var description = IntentDescription("Send Post with text content")

    @Parameter(title: "Text Content")
    var content: String?

    @Parameter(title: "Accounts")
    var accounts: [AccountAppEntity]?

    @Parameter(title: "Visibility", default: .public)
    var visibility: PostVisibilityAppEnum?

    static var parameterSummary: some ParameterSummary {
        Summary("Post \(\.$content) on Mastodon") {
            \.$visibility
            \.$accounts
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$accounts, \.$visibility, \.$content)) { accounts, visibility, content in
            DisplayRepresentation(
                title: "Post on Mastodon",
                subtitle: "\(content!). Post via \(accounts!, format: .list(type: .and)). (\(visibility!))"
            )
        }
        IntentPrediction(parameters: (\.$content, \.$visibility)) { content, visibility in
            DisplayRepresentation(
                title: "Post on Mastodon",
                subtitle: "\(content!). (\(visibility!))"
            )
        }
        IntentPrediction(parameters: (\.$content)) { content in
            DisplayRepresentation(
                title: "Post on Mastodon",
                subtitle: "\(content!)"
            )
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[PostAppEntity]> {
        // Resolve every parameter before the first network call. A needsValueError
        // restarts perform() from the top, and publishing is not idempotent across
        // passes — each pass mints a fresh idempotency key.
        guard let content, !content.isEmpty else {
            throw $content.needsValueError(.contentParameterPrompt)
        }

        let statusVisibility = (visibility ?? .public).statusVisibility

        // Either the accounts the user picked, or the active account as a fallback.
        let authenticationBoxes: [MastodonAuthenticationBox]
        if let accounts, !accounts.isEmpty {
            let identifiers = Set(accounts.compactMap { UUID(uuidString: $0.id) })
            authenticationBoxes = AuthenticationServiceProvider.shared
                .mastodonAuthenticationBoxes
                .filter { identifiers.contains($0.authentication.identifier) }
            guard !authenticationBoxes.isEmpty else {
                throw SendPostError.accountsUnavailable
            }
        } else if let activeUser = AuthenticationServiceProvider.shared.currentActiveUser.value {
            authenticationBoxes = [activeUser]
        } else {
            throw SendPostError.noAccount
        }

        let api = APIService.isolatedService()
        var posts: [PostAppEntity] = []

        for authenticationBox in authenticationBoxes {
            let response: Mastodon.Response.Content<Mastodon.Entity.Status>
            do {
                response = try await api.publishStatus(
                    domain: authenticationBox.domain,
                    idempotencyKey: UUID().uuidString,
                    query: .init(
                        status: content,
                        mediaIDs: nil,
                        pollOptions: nil,
                        pollExpiresIn: nil,
                        inReplyToID: nil,
                        quotingID: nil,
                        sensitive: nil,
                        spoilerText: nil,
                        visibility: statusVisibility,
                        quotePolicy: .nobody,  // TODO: update intents to include quotability
                        language: nil
                    ),
                    authenticationBox: authenticationBox
                )
            } catch {
                throw SendPostError.postingFailed(error.intentFailureReason)
            }

            var post = PostAppEntity()
            post.url = response.value.url.flatMap(URL.init(string:))
            post.acct = response.value.account.acct
            post.content = content
            posts.append(post)
        }

        return .result(value: posts)
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum SendPostError: Error, CustomLocalizedStringResourceConvertible {
    case noAccount
    case accountsUnavailable
    case postingFailed(String)

    // Only CustomLocalizedStringResourceConvertible errors surface a real message
    // in Shortcuts; a bare Error (even a LocalizedError) shows a generic failure.
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noAccount:
            return "Log in to a Mastodon account to post."
        case .accountsUnavailable:
            return "The selected accounts are no longer logged in."
        case .postingFailed(let reason):
            return "Posting failed. \(reason)"
        }
    }
}

fileprivate extension Error {
    /// Reproduces the failure reason the legacy intent response composed.
    var intentFailureReason: String {
        guard let error = self as? LocalizedError else { return localizedDescription }
        return [
            error.errorDescription,
            error.failureReason,
            error.recoverySuggestion
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static var contentParameterPrompt: Self {
        "What content to post?"
    }
    static func accountsParameterDisambiguationIntro(count: Int, accounts: AccountAppEntity) -> Self {
        "There are \(count) options matching ‘\(accounts)’."
    }
    static func accountsParameterConfirmation(accounts: AccountAppEntity) -> Self {
        "Just to confirm, you wanted ‘\(accounts)’?"
    }
    static func visibilityParameterDisambiguationIntro(count: Int, visibility: PostVisibilityAppEnum) -> Self {
        "There are \(count) options matching ‘\(visibility)’."
    }
    static func visibilityParameterConfirmation(visibility: PostVisibilityAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(visibility)’?"
    }
    static var responseSuccess: Self {
        "Post was sent successfully."
    }
    static func responseFailure(failureReason: String) -> Self {
        "Posting failed. \(failureReason)"
    }
}

