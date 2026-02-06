// Copyright © 2025 Mastodon gGmbH. All rights reserved.


import SwiftUI

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    var contentView: Content

    init(@ViewBuilder content: () -> Content) {
        self.contentView = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator

        scrollView.maximumZoomScale = 5
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true

        let hosted = context.coordinator.hostingController
        hosted.view.translatesAutoresizingMaskIntoConstraints = false
        hosted.view.backgroundColor = .clear
        scrollView.addSubview(hosted.view)
        NSLayoutConstraint.activate([
            hosted.view.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            hosted.view.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = contentView
        context.coordinator.hostingController.view.setNeedsLayout()
        context.coordinator.hostingController.view.layoutIfNeeded()

        context.coordinator.hostingController.view.frame = CGRect(
            origin: .zero,
            size: uiView.bounds.size
        )
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableScrollView
        let hostingController: UIHostingController<Content>

        init(_ parent: ZoomableScrollView) {
            self.parent = parent
            self.hostingController = UIHostingController(rootView: parent.contentView)
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }

    }
}
