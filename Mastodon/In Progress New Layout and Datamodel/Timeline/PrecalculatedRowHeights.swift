// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import SwiftUI

@MainActor
final class ViewMeasurer {
    static let shared = ViewMeasurer()
    
    private let host = UIHostingController(rootView: AnyView(EmptyView()))
    
    init() {
        let throwawayView = Text("This is some text just to give the system something to layout so that it gets the correct measurements when we measure things for real. Without this, the first use of the measurer gives a height that is too short.")
        let _ = immediatelyMeasureHeight(throwawayView, width: 300)
    }
    
    func calculateHeightImmediately(for viewModel: MastodonPostViewModel, contentConcealModel: ContentConcealViewModel, filterContext: Mastodon.Entity.FilterContext?, threadedContext: ThreadedConversationModel.ThreadContext?, contentWidth: CGFloat, totalWidth: CGFloat) -> PrecalculatedHeight {
        
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory // so that this offscreen view still respects the user's current settings
        
        let view = MastodonPostRowView(contentWidth: contentWidth, precalculatedHeight: nil, actionHandler: nil, threadedContext: threadedContext, filterContext: filterContext)
            .environment(viewModel)
            .environment(contentConcealModel)
            .environment(TimestampUpdater.timestamper(withInterval: 60))
            .environment(\.sizeCategory, ContentSizeCategory(contentSizeCategory) ?? .medium)
            .padding(EdgeInsets(top: 0, leading: standardPadding, bottom: 0, trailing: doublePadding))
        let height = immediatelyMeasureHeight(view, width: totalWidth)
        return PrecalculatedHeight(contentWidth: contentWidth, contentConcealed: contentConcealModel.currentMode, showingTranslation: viewModel.isShowingTranslation == true, calculatedHeight: height)
    }
    
    func calculateHeight(for viewModel: MastodonPostViewModel, contentConcealModel: ContentConcealViewModel, filterContext: Mastodon.Entity.FilterContext?, threadedContext: ThreadedConversationModel.ThreadContext?, contentWidth: CGFloat, totalWidth: CGFloat) async -> PrecalculatedHeight {
        
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory // so that this offscreen view still respects the user's current settings
        
        let view = MastodonPostRowView(contentWidth: contentWidth, precalculatedHeight: nil, actionHandler: nil, threadedContext: threadedContext, filterContext: filterContext)
            .environment(viewModel)
            .environment(contentConcealModel)
            .environment(TimestampUpdater.timestamper(withInterval: 60))
            .environment(\.sizeCategory, ContentSizeCategory(contentSizeCategory) ?? .medium)
            .padding(EdgeInsets(top: 0, leading: standardPadding, bottom: 0, trailing: doublePadding))
        let height = await measureHeight(view, width: totalWidth)
        return PrecalculatedHeight(contentWidth: contentWidth, contentConcealed: contentConcealModel.currentMode, showingTranslation: viewModel.isShowingTranslation == true, calculatedHeight: height)
    }
  
#if DEBUG
    let SECONDS_DELAY_BETWEEN_MEASUREMENTS: Int = 1
#else
    let SECONDS_DELAY_BETWEEN_MEASUREMENTS: Int = 0
#endif
    
    func measureHeight<V: View>(_ view: V, width: CGFloat) async -> CGFloat {
        host.rootView = AnyView(view)
        host.view.bounds = CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude)
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        let result = await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(SECONDS_DELAY_BETWEEN_MEASUREMENTS)) {
                continuation.resume(returning: self.host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height)
            }
        }
        return ceil(result + 0.5) // the ceil and + 0.5 arrived at through observation, attempting to mimic the actual system layout behavior as closely as possible.
    }
    
    func immediatelyMeasureHeight<V: View>(_ view: V, width: CGFloat) -> CGFloat {
        host.rootView = AnyView(view)
        host.view.bounds = CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude)
        host.view.layoutIfNeeded()
        let result = self.host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return result
    }
}
