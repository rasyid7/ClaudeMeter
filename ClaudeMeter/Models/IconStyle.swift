//
//  IconStyle.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-12-28.
//

import Foundation

/// Menu bar icon display style
enum IconStyle: String, CaseIterable, Identifiable, Sendable, Codable {
    case battery        // Gradient bar + percentage (DEFAULT)
    case circular       // Donut gauge with percentage in center
    case minimal        // Just color-coded percentage text
    case segments       // 5 segments like signal bars
    case dualBar        // Two stacked bars: session + weekly
    case time           // Percentage + reset time display

    var id: String { rawValue }

    /// Custom decoding to support migration from old "gauge" style
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        // Support old "gauge" style by mapping it to "time"
        let normalizedValue = rawValue == "gauge" ? "time" : rawValue
        guard let style = IconStyle(rawValue: normalizedValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown icon style: \(rawValue)")
        }
        self = style
    }

    /// Display name for settings UI
    var displayName: String {
        switch self {
        case .battery: return "Battery"
        case .circular: return "Circular"
        case .minimal: return "Minimal"
        case .segments: return "Segments"
        case .dualBar: return "Dual Bar"
        case .time: return "Time"
        }
    }

    /// Description for accessibility
    var accessibilityDescription: String {
        switch self {
        case .battery: return "Battery-style bar with percentage"
        case .circular: return "Circular gauge with percentage in center"
        case .minimal: return "Minimal percentage only"
        case .segments: return "Segmented bar indicator"
        case .dualBar: return "Two bars showing session and weekly usage"
        case .time: return "Percentage with session reset time"
        }
    }
}
