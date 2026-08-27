// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct AsyncTapModifier: ViewModifier {
    let onTap: () async throws -> Void
    let onError: (Error) -> Void
    @State private var isInProcess = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if isInProcess {
                ProgressView()
                    .progressViewStyle(.circular)
                    
            }
        }
        .onTapGesture {
            guard !isInProcess else { return }
            isInProcess = true
            Task {
                defer { isInProcess = false }
                do {
                    try await onTap()
                } catch { onError(error) }
            }
        }
    }
}

extension View {
    func onAsyncTap(_ onTap: @escaping () async throws -> Void, onError: @escaping (Error) -> Void) -> some View {
        modifier(AsyncTapModifier(onTap: onTap, onError: onError))
    }
}
