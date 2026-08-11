import Foundation

/// Formats a duration in seconds the way the original Thyme did:
/// `MM:SS` below one hour, `HH:MM:SS` from one hour up.
enum TimeFormatter {
    /// `MM:SS` or `HH:MM:SS`, depending on the length.
    static func clock(_ interval: TimeInterval) -> String {
        let (hours, minutes, seconds) = components(of: interval)

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Always `HH:MM:SS`.
    static func full(_ interval: TimeInterval) -> String {
        let (hours, minutes, seconds) = components(of: interval)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// Splits a duration into whole hours, minutes and seconds.
    /// A negative or invalid value becomes zero.
    static func components(of interval: TimeInterval) -> (hours: Int, minutes: Int, seconds: Int) {
        guard interval.isFinite, interval > 0 else { return (0, 0, 0) }

        let total = Int(interval.rounded(.down))
        return (total / 3600, (total / 60) % 60, total % 60)
    }
}
