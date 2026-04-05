//
//  UsageData.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import Foundation

/// Extra usage (credits) data
struct ExtraUsage: Codable, Equatable, Sendable {
    let monthlyLimit: Int
    let usedCredits: Double
    let utilization: Double

    enum CodingKeys: String, CodingKey {
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
    }
}

/// Complete usage data across all limit types
struct UsageData: Codable, Equatable, Sendable {
    /// 5-hour rolling session usage
    let sessionUsage: UsageLimit

    /// 7-day weekly usage across all models
    let weeklyUsage: UsageLimit

    /// 7-day Sonnet-specific usage (nil if not used)
    let sonnetUsage: UsageLimit?

    /// Extra usage credits (nil if not enabled)
    let extraUsage: ExtraUsage?

    /// Timestamp of when this data was fetched
    let lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case sessionUsage = "session_usage"
        case weeklyUsage = "weekly_usage"
        case sonnetUsage = "sonnet_usage"
        case extraUsage = "extra_usage"
        case lastUpdated = "last_updated"
    }
}

extension UsageData {
    /// Returns the primary usage level for menu bar display
    var primaryStatus: UsageStatus {
        sessionUsage.status
    }

    /// Human-readable staleness indicator
    var freshnessDescription: String {
        let elapsed = Date().timeIntervalSince(lastUpdated)
        if elapsed < 60 {
            return "just now"
        } else if elapsed < 3600 {
            return "\(Int(elapsed / 60)) minutes ago"
        } else {
            return "\(Int(elapsed / 3600)) hours ago"
        }
    }

    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > Constants.Refresh.stalenessThreshold
    }
}
