import Foundation

public enum NotificationSettingsStorageError: Error {
  case save
  case load
  case delete
}

public struct NotificationSettingsStorage {
  private static let group =
    "group.chat.dvd.Daria.Notification-Service-Extension"

  // The Web Push key set is shared with the Notification Service Extension via
  // the app group's shared UserDefaults. A keychain access group keyed on the
  // app group does not reliably share keychain items between the host app and
  // the extension, so the extension could not read the key set to decrypt
  // notifications.
  private static func keySetKey(_ account: String) -> String {
    "webPushKeySet/\(account)"
  }

  public static func saveKeySet(account: String, keySet: String) throws {
    UserDefaults(suiteName: group)?.set(keySet, forKey: keySetKey(account))
  }

  public static func loadKeySet(account: String) throws -> String? {
    UserDefaults(suiteName: group)?.string(forKey: keySetKey(account))
  }

  public static func deleteKeySet(account: String) throws {
    UserDefaults(suiteName: group)?.removeObject(forKey: keySetKey(account))
  }

  public static func setBadgeCount(badgeCount: Int) {
    UserDefaults(suiteName: group)?.set(
      badgeCount,
      forKey: "badgeCount",
    )
  }

  public static func getBadgeCount() -> Int? {
    UserDefaults(suiteName: group)?.integer(forKey: "badgeCount")
  }

  public static func setShowImageInNotification(showImageInNotification: Bool) {
    UserDefaults(suiteName: group)?.set(
      showImageInNotification,
      forKey: "showImageInNotification",
    )
  }

  public static func getShowImageInNotification() -> Bool? {
    UserDefaults(suiteName: group)?.object(forKey: "showImageInNotification")
      as? Bool
  }

  public static func setShowEmojiInReactionNotification(
    showEmojiInReactionNotification: Bool
  ) {
    UserDefaults(suiteName: group)?.set(
      showEmojiInReactionNotification,
      forKey: "showEmojiInReactionNotification",
    )
  }

  public static func getShowEmojiInReactionNotification() -> Bool? {
    UserDefaults(suiteName: group)?.object(
      forKey: "showEmojiInReactionNotification",
    ) as? Bool
  }
}
