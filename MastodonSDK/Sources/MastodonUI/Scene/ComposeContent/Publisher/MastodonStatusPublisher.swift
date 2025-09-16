//
//  MastodonStatusPublisher.swift
//  
//
//  Created by MainasuK on 2021-12-1.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonCore
import MastodonSDK

public final class MastodonStatusPublisher: NSObject, ProgressReporting {
    // refer
    public let replyTo: MastodonStatus?
    // content warning
    public let isContentWarningComposing: Bool
    public let contentWarning: String
    // status content
    public let content: String
    // quoted status
    public let quoting: Mastodon.Entity.Status.ID?
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
    public let quotePolicy: Mastodon.Entity.Source.QuotePolicy?
    // language
    public let language: String
    
    // Output
    let _progress = Progress()
    public var progress: Progress { _progress }
    @Published var _state: StatusPublisherState = .pending
    public var state: Published<StatusPublisherState>.Publisher { $_state }
    
    public var reactor: StatusPublisherReactor?

    public init(
        replyTo: MastodonStatus?,
        isContentWarningComposing: Bool,
        contentWarning: String,
        content: String,
        quoting: Mastodon.Entity.Status.ID?,
        isMediaSensitive: Bool,
        attachmentViewModels: [AttachmentViewModel],
        isPollComposing: Bool,
        pollOptions: [PollComposeItem.Option],
        pollExpireConfigurationOption: PollComposeItem.ExpireConfiguration.Option,
        pollMultipleConfigurationOption: PollComposeItem.MultipleConfiguration.Option,
        visibility: Mastodon.Entity.Status.Visibility,
        quotePolicy: Mastodon.Entity.Source.QuotePolicy?,
        language: String
    ) {
        self.replyTo = replyTo
        self.isContentWarningComposing = isContentWarningComposing
        self.contentWarning = contentWarning
        self.content = content
        self.quoting = quoting
        self.isMediaSensitive = isMediaSensitive
        self.attachmentViewModels = attachmentViewModels
        self.isPollComposing = isPollComposing
        self.pollOptions = pollOptions
        self.pollExpireConfigurationOption = pollExpireConfigurationOption
        self.pollMultipleConfigurationOption = pollMultipleConfigurationOption
        self.visibility = visibility
        self.quotePolicy = quotePolicy
        self.language = language
    }
    
}

// MARK: - StatusPublisher
extension MastodonStatusPublisher: StatusPublisher {

    public func publish(
        api: APIService,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> StatusPublishResult {
        let idempotencyKey = UUID().uuidString
        
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
                    break
                case let .uploadedMastodonAttachment(attachment):
                    attachmentIDs.append(attachment.id)

                    _ = try await api.updateMedia(
                        domain: authenticationBox.domain,
                        attachmentID: attachment.id,
                        query: .init(
                            file: nil,
                            thumbnail: nil,
                            description: attachmentViewModel.caption,
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
        
        do {
            let inReplyToID: Mastodon.Entity.Status.ID? = try await PersistenceManager.shared.backgroundManagedObjectContext.perform {
                guard let replyTo = self.replyTo else { return nil }
                return replyTo.id
            }
            
            let query = Mastodon.API.Statuses.PublishStatusQuery(
                status: content,
                mediaIDs: attachmentIDs.isEmpty ? nil : attachmentIDs,
                pollOptions: pollOptions,
                pollExpiresIn: pollExpiresIn,
                inReplyToID: inReplyToID,
                quotingID: quoting,
                sensitive: isMediaSensitive,
                spoilerText: isContentWarningComposing ? contentWarning : nil,
                visibility: visibility,
                quotePolicy: quotePolicy,
                language: language
            )
            
            let publishResponse = try await api.publishStatus(
                domain: authenticationBox.domain,
                idempotencyKey: idempotencyKey,
                query: query,
                authenticationBox: authenticationBox
            )
            progress.completedUnitCount += publishStatusTaskCount
            _state = .success
            return .post(publishResponse)
        } catch {
            _state = .failure(error)
            throw error
        }
    }
}
