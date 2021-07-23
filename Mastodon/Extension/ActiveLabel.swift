//extension ActiveEntity {
//
//    var accessibilityLabelDescription: String {
//        switch self.type {
//        case .email:    return L10n.Common.Controls.Status.Tag.email
//        case .hashtag:  return L10n.Common.Controls.Status.Tag.hashtag
//        case .mention:  return L10n.Common.Controls.Status.Tag.mention
//        case .url:      return L10n.Common.Controls.Status.Tag.url
//        case .emoji:    return L10n.Common.Controls.Status.Tag.emoji
//        }
//    }
//
//    var accessibilityValueDescription: String {
//        switch self.type {
//        case .email(let text, _):           return text
//        case .hashtag(let text, _):         return text
//        case .mention(let text, _):         return text
//        case .url(_, let trimmed, _, _):    return trimmed
//        case .emoji(let text, _, _):        return text
//        }
//    }
//
//    func accessibilityElement(in accessibilityContainer: Any) -> ActiveLabelAccessibilityElement? {
//        if case .emoji = self.type {
//            return nil
//        }
//
//        let element = ActiveLabelAccessibilityElement(accessibilityContainer: accessibilityContainer)
//        element.accessibilityTraits = .button
//        element.accessibilityLabel = accessibilityLabelDescription
//        element.accessibilityValue = accessibilityValueDescription
//        return element
//    }
//}

//final class ActiveLabelAccessibilityElement: UIAccessibilityElement {
//    var index: Int!
//}
//
// MARK: - UIAccessibilityContainer
//extension ActiveLabel {
//
//    func createAccessibilityElements() -> [UIAccessibilityElement] {
//        var elements: [UIAccessibilityElement] = []
//
//        let element = ActiveLabelAccessibilityElement(accessibilityContainer: self)
//        element.accessibilityTraits = .staticText
//        element.accessibilityLabel = accessibilityLabel
//        element.accessibilityFrame = superview!.convert(frame, to: nil)
//        element.accessibilityLanguage = accessibilityLanguage
//        elements.append(element)
//
//        for entity in activeEntities {
//            guard let element = entity.accessibilityElement(in: self) else { continue }
//            var glyphRange = NSRange()
//            layoutManager.characterRange(forGlyphRange: entity.range, actualGlyphRange: &glyphRange)
//            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
//            element.accessibilityFrame = self.convert(rect, to: nil)
//            element.accessibilityContainer = self
//            elements.append(element)
//        }
//
//        return elements
//    }
//
//}
