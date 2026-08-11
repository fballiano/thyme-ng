import Foundation
import Testing
@testable import ThymeNG

/// A clock the test moves by hand.
@MainActor
private final class FakeClock {
    var instant = ContinuousClock.now

    func advance(_ seconds: Double) {
        instant = instant.advanced(by: .seconds(seconds))
    }
}

@MainActor
@Suite("Stopwatch")
struct StopwatchTests {
    private func makeStopwatch() -> (Stopwatch, FakeClock) {
        let clock = FakeClock()
        return (Stopwatch(now: { clock.instant }), clock)
    }

    @Test("A new stopwatch is stopped and empty")
    func initialState() {
        let (watch, _) = makeStopwatch()

        #expect(watch.isStopped)
        #expect(!watch.isRunning)
        #expect(!watch.isPaused)
        #expect(watch.currentElapsed == 0)
    }

    @Test("It counts while it runs")
    func counts() {
        let (watch, clock) = makeStopwatch()

        watch.start()
        clock.advance(42)

        #expect(watch.isRunning)
        #expect(watch.currentElapsed == 42)
    }

    @Test("A pause holds the value")
    func pauseHoldsValue() {
        let (watch, clock) = makeStopwatch()

        watch.start()
        clock.advance(10)
        watch.pause()
        clock.advance(100)

        #expect(watch.isPaused)
        #expect(watch.currentElapsed == 10)
    }

    @Test("Continuing adds to the earlier value")
    func continueAdds() {
        let (watch, clock) = makeStopwatch()

        watch.start()
        clock.advance(10)
        watch.pause()
        clock.advance(100)
        watch.start()
        clock.advance(5)

        #expect(watch.isRunning)
        #expect(watch.currentElapsed == 15)
    }

    @Test("Stopping returns the value and resets")
    func stopReturnsValue() {
        let (watch, clock) = makeStopwatch()

        watch.start()
        clock.advance(30)

        #expect(watch.stop() == 30)
        #expect(watch.isStopped)
        #expect(watch.currentElapsed == 0)
    }

    @Test("Toggle switches between run and pause")
    func toggles() {
        let (watch, clock) = makeStopwatch()

        watch.toggle()
        #expect(watch.isRunning)

        clock.advance(3)
        watch.toggle()
        #expect(watch.isPaused)
        #expect(watch.currentElapsed == 3)

        watch.toggle()
        #expect(watch.isRunning)
    }

    @Test("Starting twice does not restart the count")
    func startIsIdempotent() {
        let (watch, clock) = makeStopwatch()

        watch.start()
        clock.advance(10)
        watch.start()
        clock.advance(5)

        #expect(watch.currentElapsed == 15)
    }

    @Test("Pausing while stopped does nothing")
    func pauseWhileStopped() {
        let (watch, _) = makeStopwatch()

        watch.pause()

        #expect(watch.isStopped)
        #expect(watch.currentElapsed == 0)
    }

    @Test("Stopping while stopped returns zero")
    func stopWhileStopped() {
        let (watch, _) = makeStopwatch()

        #expect(watch.stop() == 0)
        #expect(watch.isStopped)
    }

    @Test("The published value follows a refresh")
    func publishedValue() {
        let (watch, clock) = makeStopwatch()

        watch.start()
        #expect(watch.elapsed == 0)

        clock.advance(7)
        watch.refresh()

        #expect(watch.elapsed == 7)
    }
}
