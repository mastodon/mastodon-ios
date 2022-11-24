//
//  OpenGraphView.swift
//  
//
//  Created by Kyle Bashour on 11/11/22.
//

import AlamofireImage
import LinkPresentation
import MastodonAsset
import MastodonCore
import UIKit

public final class LinkPreviewButton: UIControl {
    private var linkPresentationTask: Task<Void, Error>?
    private var url: URL?

    private let containerStackView = UIStackView()
    private let labelStackView = UIStackView()

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        layer.cornerCurve = .continuous
        layer.cornerRadius = 10
        layer.borderColor = ThemeService.shared.currentTheme.value.separator.cgColor
        backgroundColor = ThemeService.shared.currentTheme.value.systemElevatedBackgroundColor

        titleLabel.numberOfLines = 2
        titleLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        titleLabel.text = "This is where I'd put a title... if I had one"
        titleLabel.textColor = Asset.Colors.Label.primary.color

        subtitleLabel.text = "Subtitle"
        subtitleLabel.numberOfLines = 1
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        subtitleLabel.textColor = Asset.Colors.Label.secondary.color
        subtitleLabel.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular), maximumPointSize: 20)

        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(subtitleLabel)
        labelStackView.layoutMargins = .init(top: 8, left: 10, bottom: 8, right: 10)
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.axis = .vertical

        containerStackView.addArrangedSubview(imageView)
        containerStackView.addArrangedSubview(labelStackView)
        containerStackView.distribution = .fill
        containerStackView.alignment = .center

        addSubview(containerStackView)

        containerStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerStackView.heightAnchor.constraint(equalToConstant: 85),
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(url: URL, trimmed: String) {
        guard url != self.url else {
            return
        }

        reset()
        subtitleLabel.text = trimmed
        self.url = url

        linkPresentationTask = Task {
            do {
                let metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)

                guard !Task.isCancelled else {
                    return
                }

                self.titleLabel.text = metadata.title
                if let result = try await metadata.imageProvider?.loadImageData() {
                    let image = UIImage(data: result.data)

                    guard !Task.isCancelled else {
                        return
                    }

                    self.imageView.image = image
                }
            } catch {
                self.subtitleLabel.text = "Error loading link preview"
            }
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        if let window = window {
            layer.borderWidth = 1 / window.screen.scale
        }
    }

    private func reset() {
        linkPresentationTask?.cancel()
        url = nil
        imageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
    }
}
