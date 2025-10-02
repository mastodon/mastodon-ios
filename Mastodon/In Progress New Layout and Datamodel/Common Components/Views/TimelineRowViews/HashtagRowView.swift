// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonLocalization
import MastodonSDK
import MastodonUI

struct HashtagRowView: View {
    
    let tag: Mastodon.Entity.Tag
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: tinySpacing) {
                Text("#\(tag.name)")
                    .foregroundStyle(.primary)
                
                Text(L10n.Plural.peopleTalking(tag.talkingPeopleCount ?? 0))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
                .frame(maxWidth: .infinity)
            WrappedLineChartView(tag: tag)
                .frame(width: 50, height: 26)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
struct WrappedLineChartView: UIViewRepresentable {
    typealias UIViewType = LineChartView
    let tag: Mastodon.Entity.Tag
    
    func makeUIView(context: Context) -> LineChartView {
        let view = LineChartView()
        view.data = points
        return view
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
        uiView.data = points
    }
    
    var points: [CGFloat] {
        (tag.history ?? [])
            .sorted(by: { $0.day < $1.day })  // latest last
            .map { entry in
                guard let point = Int(entry.accounts) else {
                    return .zero
                }
                return CGFloat(point)
            }
    }
    
}
