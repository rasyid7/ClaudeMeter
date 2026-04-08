//
//  UsageLimit.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import Foundation

/// Type of usage limit for display purposes
enum UsageLimitType: Codable, Equatable, Sendable {
    case session
    case weekly
    case sonnet
}

/// A single usage limit (session, weekly, or Sonnet)
struct UsageLimit: Codable, Equatable, Sendable {
    /// Utilization percentage (0-100)
    let utilization: Double

    /// ISO8601 timestamp when limit resets (nil when usage period hasn't started)
    let resetAt: Date?

    /// Type of limit (for contextual display messages)
    let type: UsageLimitType

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetAt = "reset_at"
        case type
    }
}

extension UsageLimit {
    /// Percentage used (0-100+) - alias for utilization
    var percentage: Double {
        utilization
    }

    /// Status level based on percentage
    /// Uses thresholds from Constants.Thresholds.Status
    var status: UsageStatus {
        switch utilization {
        case 0..<Constants.Thresholds.Status.warningStart:
            return .safe
        case Constants.Thresholds.Status.warningStart..<Constants.Thresholds.Status.criticalStart:
            return .warning
        default:
            return .critical
        }
    }

    /// Human-readable reset time (shows days/hours/minutes as appropriate)
    /// Returns context-appropriate message if resetAt is nil (usage period not started)
    var resetDescription: String {
        guard let resetAt else {
            switch type {
            case .session:
                return "Starts when a message is sent"
            case .weekly, .sonnet:
                return "Starts when session begins"
            }
        }

        let now = Date()
        let timeInterval = resetAt.timeIntervalSince(now)

        if timeInterval <= 0 {
            return "now"
        }

        let days = Int(timeInterval) / 86400
        let hours = (Int(timeInterval) % 86400) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60

        if days > 0 {
            if hours > 0 {
                return "in \(days) day\(days == 1 ? "" : "s") \(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "in \(days) day\(days == 1 ? "" : "s")"
            }
        } else if hours > 0 && minutes > 0 {
            return "in \(hours) hour\(hours == 1 ? "" : "s") \(minutes) min"
        } else if hours > 0 {
            return "in \(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "in \(minutes) min"
        }
    }

    /// Exact reset time formatted in user's timezone for tooltip display
    /// Returns empty string if resetAt is nil
    var resetTimeFormatted: String {
        guard let resetAt else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter.string(from: resetAt)
    }

    /// Check if limit has been exceeded
    var isExceeded: Bool {
        utilization >= 100
    }

    /// Check if reset time has passed but usage hasn't reset
    var isResetting: Bool {
        guard let resetAt else { return false }
        return resetAt < Date() && utilization > 0
    }

    /// Returns true if current usage rate will likely exceed limit before reset
    /// - Parameter windowDuration: Duration of the usage window (e.g., 5 hours for session)
    func isAtRisk(windowDuration: TimeInterval) -> Bool {
        guard let resetAt else { return false }
        let now = Date()
        guard resetAt > now else { return false }

        let windowStart = resetAt.addingTimeInterval(-windowDuration)
        let elapsed = now.timeIntervalSince(windowStart)
        guard elapsed > 0 else { return false }

        let timeElapsedPct = elapsed / windowDuration
        let usagePct = min(utilization, 100) / 100
        guard timeElapsedPct > 0 else { return false }

        return (usagePct / timeElapsedPct) > Constants.Pacing.riskThreshold
    }
}
