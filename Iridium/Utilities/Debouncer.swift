//
//  Debouncer.swift
//  Iridium
//

import Foundation

actor Debouncer {
    private let duration: Duration
    private var task: Task<Void, Never>?

    init(duration: Duration) {
        self.duration = duration
    }

    func debounce(_ action: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            await action()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
