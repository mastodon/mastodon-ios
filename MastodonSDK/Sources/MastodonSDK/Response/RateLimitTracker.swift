// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

@Observable public class RateLimitViewModel {
    private(set) var currentState: Mastodon.Response.RateLimit?
    
    private var clockUpdateTimer: Timer?
    
    private init() {}
    
    public static let shared = RateLimitViewModel()
    public private(set) var previousRequests = [String]()
    
    public func didMakeRequest(_ debugName: String) {
        guard UserDefaults.standard.showRateLimitTracker else { return }
        previousRequests.append(Mastodon.API.httpHeaderDateFormatter.string(from: .now) + ": " + debugName)
        let limit = currentState?.limit ?? 300
        if previousRequests.count > currentState?.limit ?? 300 {
            previousRequests = Array(previousRequests.suffix(limit))
        }
    }
    
    func didReceiveRateLimit(_ rateLimit: Mastodon.Response.RateLimit) {
        currentState = rateLimit
        timeRemainingLabel = formatTimeRemaining(untilResetTime: rateLimit.reset)
       
        if clockUpdateTimer == nil && UserDefaults.standard.showRateLimitTracker {
            DispatchQueue.main.async {
                self.clockUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] timer in
                    self?.timeRemainingLabel = self?.formatTimeRemaining(untilResetTime: self?.currentState?.reset)
                    if !UserDefaults.standard.showRateLimitTracker {
                        timer.invalidate()
                        self?.clockUpdateTimer = nil
                    }
                })
            }
        }
    }
    
    var usedWidth: CGFloat {
        guard let currentState else { return 0 }
        return CGFloat(currentState.limit - currentState.remaining)
    }
    
    var remainingWidth: CGFloat {
        guard let currentState else { return 300 }
        return CGFloat(currentState.remaining)
    }
    
    var timeRemainingLabel: String?
    
    private func formatTimeRemaining(untilResetTime resetTime: Date?) -> String? {
        guard let resetTime else { return nil }
        let intervalRemaining = resetTime.timeIntervalSinceNow
        guard intervalRemaining > 0 else { return nil }
        return RateLimitViewModel.remainingTimeFormatter.string(from: intervalRemaining)
    }
    
    static private let remainingTimeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()
}

public struct RateLimitTracker: View {
    @Environment(RateLimitViewModel.self) var viewModel
    
    let _height: CGFloat = 20
    
    public init() {
    }
        
    public var body: some View {
        if let timeRemainingLabel = viewModel.timeRemainingLabel {
            ZStack(alignment: .trailing) {
                HStack(spacing: 0) {
                    Color.gray.opacity(0.6)
                        .frame(width: viewModel.usedWidth, height: _height)
                    Color.gray.opacity(0.2)
                        .frame(width: viewModel.remainingWidth, height: _height)
                }
                Text(timeRemainingLabel)
                    .font(.footnote)
                    .monospaced()
                    .padding(.horizontal)
            }
            .padding(1)
            .background() {
                Color.white
            }
        }
    }
}
