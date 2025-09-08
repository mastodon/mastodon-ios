// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI

@Observable class TimestampUpdater {
    var timestamp: Date = .now
    private var timer: Timer?
    
    private init(_ interval: TimeInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] _ in
            Task { @MainActor in
                self?.timestamp = .now
            }
        })
    }
    
    private static var instances = [TimeInterval : TimestampUpdater]()

    public static func timestamper(withInterval interval: TimeInterval) -> TimestampUpdater {
        if let existing = instances[interval] {
            return existing
        } else {
            let fresh = TimestampUpdater(interval)
            instances[interval] = fresh
            return fresh
        }
    }
}
