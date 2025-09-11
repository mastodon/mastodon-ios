// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreData
import CoreDataStack
import MastodonCore
import MastodonSDK
import Combine

public final class MastodonEditStatusPublisher: NSObject, ProgressReporting {

    // Input
    public let statusID: Status.ID
    public let author: Mastodon.Entity.Account

    // content warning
    public let isContentWarningComposing: Bool
    public let contentWarning: String
    // status content
    public let content: String
    // media
    public let isMediaSensitive: Bool
    public let attachmentViewModels: [AttachmentViewModel]
    // poll
    public let isPollComposing: Bool
    public let pollOptions: [PollComposeItem.Option]
    public let pollExpireConfigurationOption: PollComposeItem.ExpireConfiguration.Option
    public let pollMultipleConfigurationOption: PollComposeItem.MultipleConfiguration.Option
    // visibility
    public let visibility: Mastodon.Entity.Status.Visibility
    public let quotability: Mastodon.Entity.Source.QuotePolicy?
    // language
    public let language: String

    // Output
    let _progress = Progress()
    public var progress: Progress { _progress }
    @Published var _state: StatusPublisherState = .pending
    public var state: Published<StatusPublisherState>.Publisher { $_state }

    public var reactor: StatusPublisherReactor?

    public init(
        statusID: Status.ID,
        author: Mastodon.Entity.Account,
        isContentWarningComposing: Bool,
        contentWarning: String,
        content: String,
        isMediaSensitive: Bool,
        attachmentViewModels: [AttachmentViewModel],
        isPollComposing: Bool,
        pollOptions: [PollComposeItem.Option],
        pollExpireConfigurationOption: PollComposeItem.ExpireConfiguration.Option,
        pollMultipleConfigurationOption: PollComposeItem.MultipleConfiguration.Option,
        visibility: Mastodon.Entity.Status.Visibility,
        quotability: Mastodon.Entity.Source.QuotePolicy?,
        language: String
    ) {
        self.author = author
        self.statusID = statusID
        self.isContentWarningComposing = isContentWarningComposing
        self.contentWarning = contentWarning
        self.content = content
        self.isMediaSensitive = isMediaSensitive
        self.attachmentViewModels = attachmentViewModels
        self.isPollComposing = isPollComposing
        self.pollOptions = pollOptions
        self.pollExpireConfigurationOption = pollExpireConfigurationOption
        self.pollMultipleConfigurationOption = pollMultipleConfigurationOption
        self.visibility = visibility
        self.quotability = quotability
        self.language = language
    }

}

// MARK: - StatusPublisher
extension MastodonEditStatusPublisher: StatusPublisher {

    public func publish(
        api: APIService,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> StatusPublishResult {
        let publishStatusTaskStartDelayWeight: Int64 = 20
        let publishStatusTaskStartDelayCount: Int64 = publishStatusTaskStartDelayWeight

        let publishAttachmentTaskWeight: Int64 = 100
        let publishAttachmentTaskCount: Int64 = Int64(attachmentViewModels.count) * publishAttachmentTaskWeight

        let publishStatusTaskWeight: Int64 = 20
        let publishStatusTaskCount: Int64 = publishStatusTaskWeight

        let taskCount = [
            publishStatusTaskStartDelayCount,
            publishAttachmentTaskCount,
            publishStatusTaskCount
        ].reduce(0, +)
        progress.totalUnitCount = taskCount
        progress.completedUnitCount = 0

        // start delay
        try? await Task.sleep(nanoseconds: 1 * .nanosPerUnit)
        progress.completedUnitCount += publishStatusTaskStartDelayWeight

        // Task: attachment

        var attachmentIDs: [Mastodon.Entity.Attachment.ID] = []
        for attachmentViewModel in attachmentViewModels {
            // set progress
            progress.addChild(attachmentViewModel.progress, withPendingUnitCount: publishAttachmentTaskWeight)
            // upload media
            do {
                switch attachmentViewModel.uploadResult {
                case .none:
                    // precondition: all media uploaded
                    throw AppError.badRequest
                case .exists:
                    guard case let AttachmentViewModel.Input.mastodonAssetUrl(_, attachmentId) = attachmentViewModel.input else {
                        throw AppError.badRequest
                    }

                    attachmentIDs.append(attachmentId)
                case let .uploadedMastodonAttachment(attachment):
                    attachmentIDs.append(attachment.id)

                    let caption = attachmentViewModel.caption
                    guard !caption.isEmpty else { continue }

                    _ = try await api.updateMedia(
                        domain: authenticationBox.domain,
                        attachmentID: attachment.id,
                        query: .init(
                            file: nil,
                            thumbnail: nil,
                            description: caption,
                            focus: nil
                        ),
                        mastodonAuthenticationBox: authenticationBox
                    ).singleOutput()

                    // TODO: allow background upload
                    // let attachment = try await attachmentViewModel.upload(context: uploadContext)
                    // let attachmentID = attachment.id
                    // attachmentIDs.append(attachmentID)
                }
            } catch {
                _state = .failure(error)
                throw error
            }
        }

        let pollOptions: [String]? = {
            guard self.isPollComposing else { return nil }
            let options = self.pollOptions.compactMap { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            return options.isEmpty ? nil : options
        }()
        let pollExpiresIn: Int? = {
            guard self.isPollComposing else { return nil }
            guard pollOptions != nil else { return nil }
            return self.pollExpireConfigurationOption.seconds
        }()

        let poll = Mastodon.API.Statuses.Poll(options: pollOptions, expiresIn: pollExpiresIn, multipleAnswers: self.pollMultipleConfigurationOption)

        let mediaAttributes: [Mastodon.API.Statuses.MediaAttributes] = attachmentViewModels.compactMap {
            if case let .mastodonAssetUrl(url: _, attachmentId: attachmentId) = $0.input {
                return Mastodon.API.Statuses.MediaAttributes(id: attachmentId, description: $0.caption)
            } else {
                return nil
            }
        }

        let query = Mastodon.API.Statuses.EditStatusQuery(
            status: content,
            mediaIDs: attachmentIDs.isEmpty ? nil : attachmentIDs,
            mediaAttributes: mediaAttributes,
            poll: poll,
            sensitive: isMediaSensitive,
            spoilerText: isContentWarningComposing ? contentWarning : nil,
            visibility: visibility,
            quotability: quotability,
            language: language
        )

        let editStatusResponse = try await api.publishStatusEdit(forStatusID: statusID,
                                                                 editStatusQuery: query,
                                                                 authenticationBox: authenticationBox)

        progress.completedUnitCount += publishStatusTaskCount
        _state = .success

        return .edit(editStatusResponse)
    }

}
