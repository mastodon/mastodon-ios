// Generated using Sourcery 1.6.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// sourcery:inline:NotificationViewContainerTableViewCell.AutoGenerateProtocolRelayDelegate
func notificationView(_ notificationView: NotificationView, menuButton button: UIButton, didSelectAction action: NotificationView.AuthorMenuAction, menuContext: NotificationView.AuthorMenuContext) {
    notificationView(notificationView, menuButton: button, didSelectAction: action, menuContext: menuContext)
}

func notificationView(_ notificationView: NotificationView, statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
    notificationView(notificationView, statusView: statusView, authorAvatarButtonDidPressed: button)
}

func notificationView(_ notificationView: NotificationView, statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta) {
    notificationView(notificationView, statusView: statusView, metaText: metaText, didSelectMeta: meta)
}

func notificationView(_ notificationView: NotificationView, statusView: StatusView, actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action) {
    notificationView(notificationView, statusView: statusView, actionToolbarContainer: actionToolbarContainer, buttonDidPressed: button, action: action)
}

func notificationView(_ notificationView: NotificationView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
    notificationView(notificationView, quoteStatusView: quoteStatusView, authorAvatarButtonDidPressed: button)
}

func notificationView(_ notificationView: NotificationView, quoteStatusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta) {
    notificationView(notificationView, quoteStatusView: quoteStatusView, metaText: metaText, didSelectMeta: meta)
}

// sourcery:end


