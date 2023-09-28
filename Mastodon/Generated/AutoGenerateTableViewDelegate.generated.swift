// Generated using Sourcery 1.9.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// sourcery:inline:DiscoveryCommunityViewController.AutoGenerateTableViewDelegate

// Generated using Sourcery
// DO NOT EDIT
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    aspectTableView(tableView, didSelectRowAt: indexPath)
}

func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    return aspectTableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
}

func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
    return aspectTableView(tableView, previewForHighlightingContextMenuWithConfiguration: configuration)
}

func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
    return aspectTableView(tableView, previewForDismissingContextMenuWithConfiguration: configuration)
}

func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
    aspectTableView(tableView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
}
// sourcery:end














