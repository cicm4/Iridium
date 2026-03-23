//
//  CalendarSignalProvider.swift
//  Iridium
//
//  Checks for upcoming calendar events using EventKit.
//  Polls every 5 minutes. Requires user opt-in + EventKit permission.
//

import EventKit
import Foundation
import OSLog

@MainActor
final class CalendarSignalProvider: SignalProvider {
    struct CalendarContext: Sendable {
        let upcomingMeetingInMinutes: Int?
        let meetingTitle: String?
    }

    private let eventStore = EKEventStore()
    private var timer: Timer?
    private var hasAccess = false

    /// Lookahead window for upcoming events.
    static let lookaheadMinutes = 30

    /// Polling interval.
    static let pollInterval: TimeInterval = 300  // 5 minutes

    private(set) var currentContext: CalendarContext?

    func start() {
        requestAccess()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        currentContext = nil
    }

    private func requestAccess() {
        Task {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    self.hasAccess = granted
                    if granted {
                        self.update()
                        self.timer = Timer.scheduledTimer(
                            withTimeInterval: Self.pollInterval,
                            repeats: true
                        ) { [weak self] _ in
                            MainActor.assumeIsolated {
                                self?.update()
                            }
                        }
                        Logger.signals.info("Calendar access granted")
                    } else {
                        Logger.signals.warning("Calendar access denied")
                    }
                }
            } catch {
                Logger.signals.error("Calendar access error: \(error.localizedDescription)")
            }
        }
    }

    func update() {
        guard hasAccess else {
            currentContext = nil
            return
        }

        let now = Date()
        let endDate = Calendar.current.date(byAdding: .minute, value: Self.lookaheadMinutes, to: now)!
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        if let nextEvent = events.first {
            let minutesUntil = Int(nextEvent.startDate.timeIntervalSince(now) / 60)
            currentContext = CalendarContext(
                upcomingMeetingInMinutes: max(0, minutesUntil),
                meetingTitle: String(nextEvent.title.prefix(64))
            )
            Logger.signals.debug("Next meeting in \(minutesUntil) min: \(nextEvent.title ?? "untitled")")
        } else {
            currentContext = nil
        }
    }
}
