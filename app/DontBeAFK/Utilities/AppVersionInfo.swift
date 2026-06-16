//
//  AppVersionInfo.swift
//  DontBeAFK
//
//  Centralized version and copyright metadata from the app bundle.
//  Marketing version is stamped at build time from package.json (Changesets).
//

import Foundation

enum AppVersionInfo {
    /// Marketing version (CFBundleShortVersionString), sourced from package.json at build time.
    static var marketingVersion: String {
        bundleString(for: "CFBundleShortVersionString") ?? "1.0.0"
    }

    /// Build number (CFBundleVersion), sourced from git commit count at build time.
    static var buildNumber: String {
        bundleString(for: "CFBundleVersion") ?? "1"
    }

    static var copyright: String {
        bundleString(for: "NSHumanReadableCopyright")
            ?? "Copyright © 2026 Erbil Nas. Open source under MIT License."
    }

    static var fullVersion: String {
        "Version \(marketingVersion) (\(buildNumber))"
    }

    static var shortVersion: String {
        "v\(marketingVersion)"
    }

    static let productDescription =
        "Keep your Mac awake by simulating mouse clicks at specified intervals.\n\nPerfect for preventing screen sleep during presentations, downloads, or remote sessions."

    private static func bundleString(for key: String) -> String? {
        Bundle.main.infoDictionary?[key] as? String
    }
}
