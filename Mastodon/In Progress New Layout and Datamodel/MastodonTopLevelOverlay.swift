// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import MastodonSDK

enum MastodonFadeInOverlay {
    case images(focusedImage: Mastodon.Entity.Attachment.ID, ImageGalleryViewModel, PageableZoomableViewModel)
    case video(MediaAttachment, PageableZoomableViewModel)
    case altText(String)
}
