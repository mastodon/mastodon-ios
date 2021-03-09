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
                if audioAttachment === AudioPlayer.shared.attachment {
                    if AudioPlayer.shared.isPlaying() {
                        AudioPlayer.shared.pause()
                    } else {
                        AudioPlayer.shared.resume()
                    }
                    if AudioPlayer.shared.currentTimeSubject.value == 0 {
                        AudioPlayer.shared.playAudio(audioAttachment: audioAttachment)
                    }
                } else {
                    AudioPlayer.shared.playAudio(audioAttachment: audioAttachment)
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
            self.resetAudioView(audioView: audioView, audioAttachment: audioAttachment)
        }
    }

    static func observePlayer(
        cell: StatusTableViewCell,
        audioAttachment: Attachment
    ) {
        let audioView = cell.statusView.audioView
        var lastCurrentTimeSubject: TimeInterval?
        AudioPlayer.shared.currentTimeSubject
            .throttle(for: 0.33, scheduler: DispatchQueue.main, latest: true)
            .compactMap { time -> (TimeInterval, Float)? in
                defer {
                    lastCurrentTimeSubject = time
                }
                guard audioAttachment === AudioPlayer.shared.attachment else { return nil }
                guard let duration = audioAttachment.meta?.original?.duration else { return nil }
                
                if let lastCurrentTimeSubject = lastCurrentTimeSubject, time != 0.0 {
                    guard abs(time - lastCurrentTimeSubject) < 0.5 else { return nil }  // debounce
                }
                
                guard !audioView.slider.isTracking else { return nil }
                return (time, Float(time / duration))
            }
            .sink(receiveValue: { time, progress in
                audioView.timeLabel.text = time.asString(style: .positional)
                audioView.slider.setValue(progress, animated: true)
            })
            .store(in: &cell.disposeBag)
        AudioPlayer.shared.playbackState
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { playbackState in
                if audioAttachment === AudioPlayer.shared.attachment {
                    let isPlaying = AudioPlayer.shared.isPlaying()
                    audioView.playButton.isSelected = isPlaying
                    audioView.slider.isEnabled = isPlaying
                    if playbackState == .stopped {
                        self.resetAudioView(audioView: audioView, audioAttachment: audioAttachment)
                    }
                } else {
                    self.resetAudioView(audioView: audioView, audioAttachment: audioAttachment)
                }
            })
            .store(in: &cell.disposeBag)
    }

    static func resetAudioView(
        audioView: AudioContainerView,
        audioAttachment: Attachment
    ) {
        audioView.playButton.isSelected = false
        audioView.slider.setValue(0, animated: false)
        audioView.slider.isEnabled = false
        guard let duration = audioAttachment.meta?.original?.duration else { return }
        audioView.timeLabel.text = duration.asString(style: .positional)
    }
}
