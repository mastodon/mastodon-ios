//
//  StatusProvider+UITableViewDelegate.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-3.
//

import Combine
import CoreDataStack
import MastodonSDK
import os.log
import UIKit

extension StatusTableViewCellDelegate where Self: StatusProvider {
    
    func handleTableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // update poll when status appear
        let now = Date()
        var pollID: Mastodon.Entity.Poll.ID?
        status(for: cell, indexPath: indexPath)
            .compactMap { [weak self] status -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Poll>, Error>? in
                guard let self = self else { return nil }
                guard let authenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else { return nil }
                guard let status = (status?.reblog ?? status) else { return nil }
                guard let poll = status.poll else { return nil }
                pollID = poll.id
                
                // not expired AND last update > 60s
                guard !poll.expired else {
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: poll %s expired. Skip for update", (#file as NSString).lastPathComponent, #line, #function, poll.id)
                    return nil
                }
                let timeIntervalSinceUpdate = now.timeIntervalSince(poll.updatedAt)
                #if DEBUG
                let autoRefreshTimeInterval: TimeInterval = 3 // speedup testing
                #else
                let autoRefreshTimeInterval: TimeInterval = 60
                #endif
                guard timeIntervalSinceUpdate > autoRefreshTimeInterval else {
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: poll %s updated in the %.2fs. Skip for update", (#file as NSString).lastPathComponent, #line, #function, poll.id, timeIntervalSinceUpdate)
                    return nil
                }
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: poll %s info update…", (#file as NSString).lastPathComponent, #line, #function, poll.id)

                return self.context.apiService.poll(
                    domain: status.domain,
                    pollID: poll.id,
                    pollObjectID: poll.objectID,
                    mastodonAuthenticationBox: authenticationBox
                )
            }
            .setFailureType(to: Error.self)
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: poll %s info fail to update: %s", (#file as NSString).lastPathComponent, #line, #function, pollID ?? "?", error.localizedDescription)
                case .finished:
                    break
                }
            }, receiveValue: { response in
                let poll = response.value
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: poll %s info updated", (#file as NSString).lastPathComponent, #line, #function, poll.id)
            })
            .store(in: &disposeBag)
        
        status(for: cell, indexPath: indexPath)
            .sink { [weak self] status in
                guard let self = self else { return }
                let status = status?.reblog ?? status
                guard let media = (status?.mediaAttachments ?? Set()).first else { return }
                guard let videoPlayerViewModel = self.context.videoPlaybackService.dequeueVideoPlayerViewModel(for: media) else { return }
                
                DispatchQueue.main.async {
                    videoPlayerViewModel.willDisplay()
                }
            }
            .store(in: &disposeBag)
    }
    
    func handleTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // os_log("%{public}s[%{public}ld], %{public}s: indexPath %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        
        status(for: cell, indexPath: indexPath)
            .sink { [weak self] status in
                guard let self = self else { return }
                guard let media = (status?.mediaAttachments ?? Set()).first else { return }
                
                if let videoPlayerViewModel = self.context.videoPlaybackService.dequeueVideoPlayerViewModel(for: media) {
                    DispatchQueue.main.async {
                        videoPlayerViewModel.didEndDisplaying()
                    }
                }
                if let currentAudioAttachment = self.context.audioPlaybackService.attachment,
                   status?.mediaAttachments?.contains(currentAudioAttachment) == true {
                    self.context.audioPlaybackService.pause()
                }
            }
            .store(in: &disposeBag)
    }
    
    func handleTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        StatusProviderFacade.coordinateToStatusThreadScene(for: .primary, provider: self, indexPath: indexPath)
    }
    
}

extension StatusTableViewCellDelegate where Self: StatusProvider {}
