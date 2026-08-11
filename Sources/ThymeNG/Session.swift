import Foundation
import SwiftData

/// One finished stretch of time.
///
/// The original stored the hours, the minutes and the seconds in three separate
/// Core Data fields. This model stores one duration in seconds instead, and
/// derives the parts when it shows them.
@Model
final class Session {
    /// When the session finished.
    var date: Date

    /// How long the session lasted, in seconds.
    var duration: TimeInterval

    /// A free label. An empty string means no tag.
    var tag: String

    init(date: Date = .now, duration: TimeInterval, tag: String = "") {
        self.date = date
        self.duration = duration
        self.tag = tag
    }
}

extension Session {
    /// `MM:SS` or `HH:MM:SS`.
    var durationText: String {
        TimeFormatter.clock(duration)
    }

    /// `HH:MM:SS - 11 Aug 2026 at 09:30 - tag`, the same shape the original used.
    var menuText: String {
        let stamp = Self.rowDateFormatter.string(from: date)
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedTag.isEmpty {
            return "\(durationText) - \(stamp)"
        }
        return "\(durationText) - \(stamp) - \(trimmedTag)"
    }

    private static let rowDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
