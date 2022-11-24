//
//  AnimatedImage.swift
//  
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import SwiftUI
import Nuke
import FLAnimatedImage

public struct AnimatedImage: UIViewRepresentable {

    public let imageURL: URL?

    public init(imageURL: URL?) {
        self.imageURL = imageURL
    }
    
    public func makeUIView(context: Context) -> FLAnimatedImageViewProxy {
        let proxy = FLAnimatedImageViewProxy(frame: .zero)
        Nuke.loadImage(with: imageURL, into: proxy.imageView)
        return proxy
    }

    public func updateUIView(_ proxy: FLAnimatedImageViewProxy, context: Context) {
        Nuke.cancelRequest(for: proxy.imageView)
        Nuke.loadImage(with: imageURL, into: proxy.imageView)
    }
}

final public class FLAnimatedImageViewProxy: UIView {
    let imageView = FLAnimatedImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        imageView.pinToParent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct AnimatedImage_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedImage(
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif")
        )
        .frame(width: 300, height: 300)
    }
}
