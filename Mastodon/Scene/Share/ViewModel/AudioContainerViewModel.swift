//
//  AudioContainerViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/9.
//

import CoreDataStack
import Foundation
import UIKit

class AudioContainerViewModel {
    static func configure(
        cell: StatusTableViewCell,
        audioAttachment: Attachment
    ) {
        guard let duration = audioAttachment.meta?.original?.duration else { return }
        let audioView = cell.statusView.audioView
        audioView.timeLabel.text = duration.asString(style: .positional)

        audioView.playButton.publisher(for: .touchUpInside)
            .sink { _ in
                let isPlaying = AudioPlayer.shared.playbackState.value == .readyToPlay || AudioPlayer.shared.playbackState.value == .playing
                if isPlaying {
                    AudioPlayer.shared.pause()
                } else {
                    if audioAttachment === AudioPlayer.shared.attachment {
                        if AudioPlayer.shared.currentTimeSubject.value == 0 {
                            AudioPlayer.shared.playAudio(audioAttachment: audioAttachment)
                        } else {
                            AudioPlayer.shared.resume()
                        }
                    } else {
                        AudioPlayer.shared.playAudio(audioAttachment: audioAttachment)
                    }
                }
            }
            .store(in: &cell.disposeBag)
        audioView.slider.publisher(for: .valueChanged)
            .sink { slider in
                let slider = slider as! UISlider
                let time = Double(slider.value) * duration
                AudioPlayer.shared.seekToTime(time: time)
            }
            .store(in: &cell.disposeBag)
        self.observePlayer(cell: cell, audioAttachment: audioAttachment)
        if audioAttachment != AudioPlayer.shared.attachment {
            self.resetAudioView(audioView: audioView)
        }
    }

    static func observePlayer(
        cell: StatusTableViewCell,
        audioAttachment: Attachment
    ) {
        let audioView = cell.statusView.audioView
        AudioPlayer.shared.currentTimeSubject
            .receive(on: DispatchQueue.main)
            .filter { _ in
                audioAttachment === AudioPlayer.shared.attachment
            }
            .sink(receiveValue: { time in
                audioView.timeLabel.text = time.asString(style: .positional)
                if let duration = audioAttachment.meta?.original?.duration, !audioView.slider.isTracking {
                    audioView.slider.setValue(Float(time / duration), animated: true)
                }
            })
            .store(in: &cell.disposeBag)
        AudioPlayer.shared.playbackState
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { playbackState in
                if audioAttachment === AudioPlayer.shared.attachment {
                    let isPlaying = playbackState == .playing || playbackState == .readyToPlay
                    audioView.playButton.isSelected = isPlaying
                    audioView.slider.isEnabled = isPlaying
                    if playbackState == .stopped {
                        self.resetAudioView(audioView: audioView)
                    }
                } else {
                    self.resetAudioView(audioView: audioView)
                }
            })
            .store(in: &cell.disposeBag)
    }

    static func resetAudioView(audioView: AudioContainerView) {
        audioView.playButton.isSelected = false
        audioView.slider.setValue(0, animated: false)
        audioView.slider.isEnabled = false
    }
}
