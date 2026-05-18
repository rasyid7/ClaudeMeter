//
//  MenuBarIconRendererTests.swift
//  ClaudeMeterTests
//
//  Created by Edd on 2026-01-09.
//

import XCTest
@testable import ClaudeMeter

@MainActor
final class MenuBarIconRendererTests: XCTestCase {
    func test_menuBarIconRendersForAllStyles() {
        let renderer = MenuBarIconRenderer()

        for style in IconStyle.allCases {
            let image = renderer.render(
                percentage: TestConstants.sessionPercentage,
                status: .safe,
                isLoading: false,
                isStale: false,
                iconStyle: style,
                weeklyPercentage: TestConstants.weeklyPercentage
            )

            XCTAssertGreaterThan(image.size.width, 0)
            XCTAssertGreaterThan(image.size.height, 0)
        }
    }

    func test_menuBarIconRendersWhenLoadingOrStale() {
        let renderer = MenuBarIconRenderer()

        let loadingImage = renderer.render(
            percentage: TestConstants.sessionPercentage,
            status: .safe,
            isLoading: true,
            isStale: false,
            iconStyle: .battery,
            weeklyPercentage: TestConstants.weeklyPercentage
        )

        let staleImage = renderer.render(
            percentage: TestConstants.sessionPercentage,
            status: .safe,
            isLoading: false,
            isStale: true,
            iconStyle: .battery,
            weeklyPercentage: TestConstants.weeklyPercentage
        )

        XCTAssertGreaterThan(loadingImage.size.width, 0)
        XCTAssertGreaterThan(loadingImage.size.height, 0)
        XCTAssertGreaterThan(staleImage.size.width, 0)
        XCTAssertGreaterThan(staleImage.size.height, 0)
    }

    func test_menuBarIconIsRenderedAsNonTemplateImage() {
        let renderer = MenuBarIconRenderer()

        let image = renderer.render(
            percentage: TestConstants.sessionPercentage,
            status: .safe,
            isLoading: false,
            isStale: false,
            iconStyle: .battery,
            weeklyPercentage: TestConstants.weeklyPercentage
        )

        XCTAssertFalse(image.isTemplate)
    }

    func test_menuBarIconIsRenderedAsTemplateImageWhenMonochromeModeSelected() {
        let renderer = MenuBarIconRenderer()

        let image = renderer.render(
            percentage: TestConstants.sessionPercentage,
            status: .safe,
            isLoading: false,
            isStale: false,
            iconStyle: .battery,
            weeklyPercentage: TestConstants.weeklyPercentage,
            isColored: false
        )

        XCTAssertTrue(image.isTemplate)
    }

    func test_menuBarIconIsRenderedAsNonTemplateImageWhenColorModeSelected() {
        let renderer = MenuBarIconRenderer()

        let image = renderer.render(
            percentage: TestConstants.sessionPercentage,
            status: .safe,
            isLoading: false,
            isStale: false,
            iconStyle: .battery,
            weeklyPercentage: TestConstants.weeklyPercentage,
            isColored: true
        )

        XCTAssertFalse(image.isTemplate)
    }
}
