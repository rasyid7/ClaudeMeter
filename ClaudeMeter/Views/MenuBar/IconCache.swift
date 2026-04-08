//
//  IconCache.swift
//  ClaudeMeter
//
//  Created by Edd on 2026-01-09.
//

import AppKit

/// Simple in-memory cache for rendered menu bar icons.
final class IconCache {
    private let cache = NSCache<NSString, NSImage>()

    init() {
        cache.countLimit = Constants.Cache.maxIconCacheSize
    }

    func get(
        percentage: Double,
        status: UsageStatus,
        isLoading: Bool,
        isStale: Bool,
        iconStyle: IconStyle,
        weeklyPercentage: Double,
        sessionResetAt: Date? = nil
    ) -> NSImage? {
        cache.object(forKey: cacheKey(
            percentage: percentage,
            status: status,
            isLoading: isLoading,
            isStale: isStale,
            iconStyle: iconStyle,
            weeklyPercentage: weeklyPercentage,
            sessionResetAt: sessionResetAt
        ))
    }

    func set(
        _ image: NSImage,
        percentage: Double,
        status: UsageStatus,
        isLoading: Bool,
        isStale: Bool,
        iconStyle: IconStyle,
        weeklyPercentage: Double,
        sessionResetAt: Date? = nil
    ) {
        cache.setObject(
            image,
            forKey: cacheKey(
                percentage: percentage,
                status: status,
                isLoading: isLoading,
                isStale: isStale,
                iconStyle: iconStyle,
                weeklyPercentage: weeklyPercentage,
                sessionResetAt: sessionResetAt
            )
        )
    }

    private func cacheKey(
        percentage: Double,
        status: UsageStatus,
        isLoading: Bool,
        isStale: Bool,
        iconStyle: IconStyle,
        weeklyPercentage: Double,
        sessionResetAt: Date? = nil
    ) -> NSString {
        let percent = String(format: "%.2f", percentage)
        let weekly = String(format: "%.2f", weeklyPercentage)
        let resetTime: String
        if let resetAt = sessionResetAt {
            let hours = Int(resetAt.timeIntervalSince(Date())) / 3600
            let minutes = (Int(resetAt.timeIntervalSince(Date())) % 3600) / 60
            resetTime = "\(hours):\(String(format: "%02d", minutes))"
        } else {
            resetTime = "none"
        }
        return "\(percent)|\(weekly)|\(resetTime)|\(status.rawValue)|\(isLoading)|\(isStale)|\(iconStyle.rawValue)" as NSString
    }
}
