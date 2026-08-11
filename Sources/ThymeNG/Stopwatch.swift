import Foundation
import Observation

/// The timer engine.
///
/// The elapsed value is always computed from a monotonic clock. The repeating
/// timer only refreshes the published value, so a missed tick, a system sleep,
/// or a change of the wall clock cannot make the value drift.
@MainActor
@Observable
final class Stopwatch {
    enum State: Equatable {
        case stopped
        case running(since: ContinuousClock.Instant, accumulated: TimeInterval)
        case paused(accumulated: TimeInterval)
    }

    /// How often the published value refreshes while the stopwatch runs.
    static let tickInterval: TimeInterval = 0.5

    private(set) var state: State = .stopped

    /// The elapsed seconds, refreshed on every tick and on every state change.
    /// Views observe this property.
    private(set) var elapsed: TimeInterval = 0

    @ObservationIgnored
    private let now: @MainActor () -> ContinuousClock.Instant

    @ObservationIgnored
    private var timer: Timer?

    /// - Parameter now: the time source. Tests replace it with a controlled clock.
    init(now: @escaping @MainActor () -> ContinuousClock.Instant = { ContinuousClock.now }) {
        self.now = now
    }

    isolated deinit {
        timer?.invalidate()
    }

    // MARK: - State

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    var isStopped: Bool {
        state == .stopped
    }

    // MARK: - Commands

    /// Starts, or continues after a pause. Does nothing if it already runs.
    func start() {
        guard !isRunning else { return }

        state = .running(since: now(), accumulated: accumulatedValue)
        startTimer()
        refresh()
    }

    /// Pauses and keeps the elapsed value. Does nothing if it does not run.
    func pause() {
        guard isRunning else { return }

        state = .paused(accumulated: currentElapsed)
        stopTimer()
        refresh()
    }

    /// Pauses if it runs, otherwise starts.
    func toggle() {
        isRunning ? pause() : start()
    }

    /// Stops and returns to zero.
    /// - Returns: the elapsed seconds at the moment of the stop.
    @discardableResult
    func stop() -> TimeInterval {
        let value = currentElapsed

        state = .stopped
        stopTimer()
        refresh()

        return value
    }

    // MARK: - Value

    /// The exact elapsed value, read straight from the clock.
    var currentElapsed: TimeInterval {
        switch state {
        case .stopped:
            return 0
        case let .paused(accumulated):
            return accumulated
        case let .running(since, accumulated):
            return accumulated + seconds(from: since, to: now())
        }
    }

    private var accumulatedValue: TimeInterval {
        switch state {
        case .stopped: return 0
        case let .paused(accumulated): return accumulated
        case let .running(_, accumulated): return accumulated
        }
    }

    /// Copies the exact value into the observed property.
    func refresh() {
        elapsed = currentElapsed
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()

        let timer = Timer(timeInterval: Self.tickInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refresh()
            }
        }

        // `.common` keeps the timer alive while a menu is open. The original
        // app used the default mode, so its clock froze while you read the menu.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func seconds(from start: ContinuousClock.Instant, to end: ContinuousClock.Instant) -> TimeInterval {
        let duration = end - start
        return TimeInterval(duration.components.seconds)
            + TimeInterval(duration.components.attoseconds) * 1e-18
    }
}
