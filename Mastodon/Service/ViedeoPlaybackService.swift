//
//  ViedeoPlaybackService.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/3/10.
//

import AVKit
import Combine
import CoreDataStack
import Foundation
import os.log

final class VideoPlaybackService {
    var disposeBag = Set<AnyCancellable>()
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.Mastodon.VideoPlaybackService.working-queue")
    private(set) var viewPlayerViewModelDict: [URL: VideoPlayerViewModel] = [:]
    
    // only for video kind
    weak var latestPlayingVideoPlayerViewModel: VideoPlayerViewModel?
}

extension VideoPlaybackService {
    private func playerViewModel(_ playerViewModel: VideoPlayerViewModel, didUpdateTimeControlStatus: AVPlayer.TimeControlStatus) {
        switch playerViewModel.videoKind {
        case .gif:
            // do nothing
            return
        case .video:
            if playerViewModel.timeControlStatus.value != .paused {
                latestPlayingVideoPlayerViewModel = playerViewModel
                
                // pause other player
                for viewModel in viewPlayerViewModelDict.values {
                    guard viewModel.timeControlStatus.value != .paused else { continue }
                    guard viewModel !== playerViewModel else { continue }
                    viewModel.pause()
                }
            } else {
                if latestPlayingVideoPlayerViewModel === playerViewModel {
                    latestPlayingVideoPlayerViewModel = nil
                    try? AVAudioSession.sharedInstance().setCategory(.soloAmbient, mode: .default)
                }
            }
        }
    }
}

extension VideoPlaybackService {
    func dequeueVideoPlayerViewModel(for media: Attachment) -> VideoPlayerViewModel? {
        // Core Data entity not thread-safe. Save attribute before enter working queue
        guard let height = media.meta?.original?.height,
              let width = media.meta?.original?.width,
              let url = URL(string: media.url),
              media.type == .gifv || media.type == .video
        else { return nil }

        let previewImageURL = media.previewURL.flatMap { URL(string: $0) }
        let videoKind: VideoPlayerViewModel.Kind = media.type == .gifv ? .gif : .video

        var _viewModel: VideoPlayerViewModel?
        workingQueue.sync {
            if let viewModel = viewPlayerViewModelDict[url] {
                _viewModel = viewModel
            } else {
                let viewModel = VideoPlayerViewModel(
                    previewImageURL: previewImageURL,
                    videoURL: url,
                    videoSize: CGSize(width: width, height: height),
                    videoKind: videoKind
                )
                viewPlayerViewModelDict[url] = viewModel
                setupListener(for: viewModel)
                _viewModel = viewModel
            }
        }
        return _viewModel
    }
    
    func playerViewModel(for playerViewController: AVPlayerViewController) -> VideoPlayerViewModel? {
        guard let url = (playerViewController.player?.currentItem?.asset as? AVURLAsset)?.url else { return nil }
        return viewPlayerViewModelDict[url]
    }

    private func setupListener(for viewModel: VideoPlayerViewModel) {
        viewModel.timeControlStatus
            .sink { [weak self] timeControlStatus in
                guard let self = self else { return }
                self.playerViewModel(viewModel, didUpdateTimeControlStatus: timeControlStatus)
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default.publisher(for: AudioPlaybackService.appWillPlayAudioNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.pauseWhenPlayAudio()
            }
            .store(in: &disposeBag)
    }
}

extension VideoPlaybackService {
    func markTransitioning(for status: Status) {
        guard let videoAttachment = status.mediaAttachments?.filter({ $0.type == .gifv || $0.type == .video }).first else { return }
        guard let videoPlayerViewModel = dequeueVideoPlayerViewModel(for: videoAttachment) else { return }
        videoPlayerViewModel.isTransitioning = true
    }
    
    func viewDidDisappear(from viewController: UIViewController?) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
        
        // note: do not retain view controller
        // pause all player when view disppear exclude full screen player and other transitioning scene
        for viewModel in viewPlayerViewModelDict.values {
            guard !viewModel.isTransitioning else {
                viewModel.isTransitioning = false
                continue
            }
            guard !viewModel.isFullScreenPresentationing else {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: isFullScreenPresentationing", (#file as NSString).lastPathComponent, #line, #function)
                continue
            }
            guard viewModel.videoKind == .video else { continue }
            viewModel.pause()
        }
    }

    func pauseWhenPlayAudio() {
        for viewModel in viewPlayerViewModelDict.values {
            guard !viewModel.isTransitioning else {
                viewModel.isTransitioning = false
                continue
            }
            guard !viewModel.isFullScreenPresentationing else {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: isFullScreenPresentationing", (#file as NSString).lastPathComponent, #line, #function)
                continue
            }
            viewModel.pause()
        }
    }
}
