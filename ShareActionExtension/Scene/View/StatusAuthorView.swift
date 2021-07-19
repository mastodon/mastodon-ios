//
//  StatusAuthorView.swift
//  
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import SwiftUI
import MastodonUI
import Nuke
import NukeFLAnimatedImagePlugin
import FLAnimatedImage

struct StatusAuthorView: View {

    let avatarImageURL: URL?
    let name: String
    let username: String

    var body: some View {
        HStack(spacing: 5) {
            AnimatedImage(imageURL: avatarImageURL)
                .frame(width: 42, height: 42)
                .cornerRadius(4)
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                Text("@" + username)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

struct StatusAuthorView_Previews: PreviewProvider {
    static var previews: some View {
        StatusAuthorView(
            avatarImageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif"),
            name: "Alice",
            username: "alice"
        )
    }
}
