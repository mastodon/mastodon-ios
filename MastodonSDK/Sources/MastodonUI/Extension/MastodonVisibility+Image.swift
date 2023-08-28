// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import CoreDataStack
import MastodonAsset

extension MastodonVisibility {

    public var image: UIImage {
        let asset: ImageAsset
        switch self {
        case .public: asset = Asset.Scene.Compose.earth
        case .unlisted: asset = Asset.Scene.Compose.people
        case .private: asset = Asset.Scene.Compose.peopleAdd
        case .direct: asset = Asset.Scene.Compose.mention
        case ._other: asset = Asset.Scene.Compose.questionmarkCircle
        }
        return asset.image.withRenderingMode(.alwaysTemplate)
    }
}
