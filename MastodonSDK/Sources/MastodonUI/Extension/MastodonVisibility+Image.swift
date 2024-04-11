// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import CoreDataStack
import MastodonAsset
import MastodonSDK

extension MastodonVisibility {

    public var image: UIImage {
        let asset: UIImage
        switch self {
        case .public: asset = Mastodon.Entity.Status.Visibility.public.image
        case .unlisted: asset = Asset.Scene.Compose.people.image
        case .private: asset = Asset.Scene.Compose.peopleAdd.image
        case .direct: asset = Asset.Scene.Compose.mention.image
        case ._other: asset = Asset.Scene.Compose.questionmarkCircle.image
        }
        return asset.withRenderingMode(.alwaysTemplate)
    }
}
