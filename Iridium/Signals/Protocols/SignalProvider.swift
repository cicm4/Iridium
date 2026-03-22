//
//  SignalProvider.swift
//  Iridium
//

import Foundation

protocol SignalProvider: AnyObject, Sendable {
    func start()
    func stop()
}
