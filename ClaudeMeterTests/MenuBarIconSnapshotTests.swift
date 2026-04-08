//
//  MenuBarIconSnapshotTests.swift
//  ClaudeMeterTests
//
//  Created by Edd on 2026-01-09.
//

import AppKit
import SnapshotTesting
import XCTest
@testable import ClaudeMeter

@MainActor
final class MenuBarIconSnapshotTests: XCTestCase {
    func test_menuBarIcon_showsBatteryStyleWhenWarning() {
        let image = renderIcon(style: .battery)

        assertSnapshot(of: image, as: .image, record: isRecording)
    }

    func test_menuBarIcon_showsCircularStyleWhenWarning() {
        let image = renderIcon(style: .circular)

        assertSnapshot(of: image, as: .image, record: isRecording)
    }

    func test_menuBarIcon_showsMinimalStyleWhenWarning() {
        let image = renderIcon(style: .minimal)

        assertSnapshot(of: image, as: .image, record: isRecording)
    }

    func test_menuBarIcon_showsSegmentsStyleWhenWarning() {
        let image = renderIcon(style: .segments)

        assertSnapshot(of: image, as: .image, record: isRecording)
    }

    func test_menuBarIcon_showsDualBarStyleWhenWarning() {
        let image = renderIcon(style: .dualBar)

        assertSnapshot(of: image, as: .image, record: isRecording)
    }

    func test_menuBarIcon_showsTimeStyleWhenWarning() {
        let resetAt = Date().addingTimeInterval(2.5 * 3600) // 2:30 remaining
        let image = renderIcon(style: .time, sessionResetAt: resetAt)

        assertSnapshot(of: image, as: .image, record: isRecording)
    }

    func test_menuBarIcon_showsLoadingIndicatorInBatteryStyle() {
        let image = renderIcon(style: .battery, status: .safe, isLoading: true)

        assertSnapshot(of: image, as: .image, record: isRecording)
    }

    func test_menuBarIcon_showsStaleIndicatorInBatteryStyle() {
        let image = renderIcon(style: .battery, status: .safe, isStale: true)

        assertSnapshot(of: image, as: .image, record: isRecording)
    }

    private func renderIcon(
        style: IconStyle,
        status: UsageStatus = .warning,
        isLoading: Bool = false,
        isStale: Bool = false,
        sessionResetAt: Date? = nil
    ) -> NSImage {
        MenuBarIconSnapshotRenderer.render(
            percentage: TestConstants.menuBarSnapshotPercentage,
            weeklyPercentage: TestConstants.menuBarSnapshotWeeklyPercentage,
            status: status,
            isLoading: isLoading,
            isStale: isStale,
            iconStyle: style,
            sessionResetAt: sessionResetAt
        )
    }

    private var isRecording: Bool {
        #if SNAPSHOT_RECORDING
        return true
        #else
        return ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
            || ProcessInfo.processInfo.arguments.contains("SNAPSHOT_RECORD")
        #endif
    }
}
