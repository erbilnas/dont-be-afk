//
//  IntervalFormatter.swift
//  DontBeAFK
//
//  Human-readable interval strings for menu bar and settings.
//

import Foundation

enum IntervalFormatter {
    static func displayString(for seconds: String) -> String {
        guard let value = Int(seconds) else { return "\(seconds)s" }
        if value >= 60, value % 60 == 0 {
            let minutes = value / 60
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        }
        return value == 1 ? "1 second" : "\(value) seconds"
    }

    static func compactString(for seconds: String) -> String {
        guard let value = Int(seconds) else { return seconds }
        if value >= 60, value % 60 == 0 {
            return "\(value / 60)m"
        }
        return "\(value)s"
    }
}
