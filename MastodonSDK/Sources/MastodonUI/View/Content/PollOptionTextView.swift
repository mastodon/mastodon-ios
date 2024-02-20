//
//  PollOptionTextView.swift
//  Mastodon
//
//  Created by Natalia Ossipova on 2023-01-13.
//

import SwiftUI
import MastodonAsset

public struct PollOptionTextView: View {

    @ObservedObject var viewModel: PollOptionTextViewModel

    public var body: some View {
        VStack {
            Text(viewModel.text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(viewModel.textColor))
                .multilineTextAlignment(viewModel.isLeftToRight ? .leading : .trailing)
                .padding([.top, .bottom], 8)
        }
    }
}

#if DEBUG
struct PollOptionTextView_Previews: PreviewProvider {
    static var previews: some View {
        PollOptionTextView(viewModel: PollOptionTextViewModel(text: "Option"))
    }
}
#endif
