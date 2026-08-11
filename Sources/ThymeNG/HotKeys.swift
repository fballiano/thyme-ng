import KeyboardShortcuts

/// The global hot keys. `KeyboardShortcuts` stores the chosen combinations in
/// `UserDefaults` and turns them off while the user records a new one, which is
/// what the original app tried to do with its "ignore while Preferences is open"
/// check.
extension KeyboardShortcuts.Name {
    static let toggle = Self("startPause")
    static let restart = Self("restart")
    static let finish = Self("finish")
}
