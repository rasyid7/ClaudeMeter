//
//  MenuBarIconSnapshotRenderer.swift
//  ClaudeMeterTests
//
//  Created by Edd on 2026-01-09.
//

import AppKit
import SwiftUI
@testable import ClaudeMeter

@MainActor
enum MenuBarIconSnapshotRenderer {
    static func render(
        percentage: Double,
        weeklyPercentage: Double,
        status: UsageStatus,
        isLoading: Bool,
        isStale: Bool,
        iconStyle: IconStyle,
        sessionResetAt: Date? = nil
    ) -> NSImage {
        let view = MenuBarIconView(
            percentage: percentage,
            status: status,
            isLoading: isLoading,
            isStale: isStale,
            iconStyle: iconStyle,
            weeklyPercentage: weeklyPercentage,
            sessionResetAt: sessionResetAt
        )
        .fixedSize()

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        renderer.isOpaque = false

        guard let image = renderer.nsImage else {
            return NSImage(
                systemSymbolName: "exclamationmark.triangle",
                accessibilityDescription: "Snapshot render failed"
            ) ?? NSImage()
        }

        image.isTemplate = false
        return image
    }
}
