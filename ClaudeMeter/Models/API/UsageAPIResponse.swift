//
//  UsageAPIResponse.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import Foundation

/// API response for usage data
struct UsageAPIResponse: Codable {
    let fiveHour: UsageLimitResponse
    let sevenDay: UsageLimitResponse
    let sevenDaySonnet: UsageLimitResponse?
    let extraUsage: ExtraUsageResponse?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case extraUsage = "extra_usage"
    }
}

/// Extra usage (credits) response from API
struct ExtraUsageResponse: Codable {
    let isEnabled: Bool
    let monthlyLimit: Int
    let usedCredits: Double
    let utilization: Double? // API may return null when usage period hasn't generated data yet
    let currency: String?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
        case currency
    }
}

/// Individual usage limit response from API
struct UsageLimitResponse: Codable {
    let utilization: Double // Percentage 0-100
    let resetsAt: String? // ISO8601 string, can be null

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

/// Mapping error for API response conversion
enum MappingError: LocalizedError {
    case invalidDateFormat
    case missingCriticalField(field: String)

    var errorDescription: String? {
        switch self {
        case .invalidDateFormat:
            return "Server returned invalid date format"
        case .missingCriticalField(let field):
            return "Server response missing critical field: \(field)"
        }
    }
}

/// Extension to map API response to domain model
extension UsageAPIResponse {
    func toDomain() throws -> UsageData {
        // Configure ISO8601 formatter with proper options
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Parse session reset date (nil when session hasn't started - e.g., after reset)
        let sessionResetDate: Date? = fiveHour.resetsAt.flatMap { iso8601Formatter.date(from: $0) }
        // When session hasn't started (resets_at is null), utilization should be 0%
        let sessionUtilization = sessionResetDate == nil ? 0.0 : fiveHour.utilization

        // Parse weekly reset date (nil when weekly limit has been reset and not started)
        let weeklyResetDate: Date? = sevenDay.resetsAt.flatMap { iso8601Formatter.date(from: $0) }
        // When weekly hasn't started (resets_at is null), utilization should be 0%
        let weeklyUtilization = weeklyResetDate == nil ? 0.0 : sevenDay.utilization

        // Handle optional sonnet usage
        let sonnetLimit: UsageLimit? = sevenDaySonnet.flatMap { sonnet in
            let sonnetResetDate: Date? = sonnet.resetsAt.flatMap { iso8601Formatter.date(from: $0) }
            // When sonnet hasn't started, utilization should be 0%
            let sonnetUtilization = sonnetResetDate == nil ? 0.0 : sonnet.utilization

            return UsageLimit(
                utilization: sonnetUtilization,
                resetAt: sonnetResetDate,
                type: .sonnet
            )
        }

        // Handle optional extra usage
        let extraUsage: ExtraUsage? = extraUsage.flatMap { extra in
            guard extra.isEnabled else { return nil }
            // utilization may be null from API; derive from usedCredits/monthlyLimit when absent
            let utilization = extra.utilization ?? (extra.monthlyLimit > 0 ? (extra.usedCredits / Double(extra.monthlyLimit) * 100) : 0.0)
            return ExtraUsage(
                monthlyLimit: extra.monthlyLimit,
                usedCredits: extra.usedCredits,
                utilization: utilization
            )
        }

        return UsageData(
            sessionUsage: UsageLimit(
                utilization: sessionUtilization,
                resetAt: sessionResetDate,
                type: .session
            ),
            weeklyUsage: UsageLimit(
                utilization: weeklyUtilization,
                resetAt: weeklyResetDate,
                type: .weekly
            ),
            sonnetUsage: sonnetLimit,
            extraUsage: extraUsage,
            lastUpdated: Date()
        )
    }
}
