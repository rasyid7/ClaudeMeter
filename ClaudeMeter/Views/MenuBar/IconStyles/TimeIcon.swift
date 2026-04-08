//
//  TimeIcon.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-12-28.
//

import SwiftUI
import Combine

/// Time-style menu bar icon showing percentage and session reset time
struct TimeIcon: View {
    let percentage: Double
    let sessionResetAt: Date?
    let status: UsageStatus
    let isLoading: Bool
    let isStale: Bool

    @State private var currentTime = Date()
    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        HStack(spacing: 2) {
            if isLoading {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(statusColor)
            } else {
                // Percentage text
                Text("\(Int(percentage))%")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(statusColor)

                // Center dot separator (interpunct)
                Text("·")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(statusColor)

                // Time until reset
                Text(timeRemainingText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(statusColor)
                    .frame(minWidth: 28, alignment: .center)
            }

            if isStale && !isLoading {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 22)
        .padding(.horizontal, 4)
        .accessibilityLabel("Usage: \(Int(percentage)) percent, resets in \(timeRemainingAccessibility)")
        .accessibilityValue(status.accessibilityDescription)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    /// Formatted time remaining until session reset (H:mm format)
    private var timeRemainingText: String {
        guard let resetAt = sessionResetAt else {
            return "-:-"
        }

        let timeInterval = resetAt.timeIntervalSince(currentTime)

        if timeInterval <= 0 {
            return "0:00"
        }

        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60

        return "\(hours):\(String(format: "%02d", minutes))"
    }

    /// Accessibility-friendly time description
    private var timeRemainingAccessibility: String {
        guard let resetAt = sessionResetAt else {
            return "unknown"
        }

        let timeInterval = resetAt.timeIntervalSince(currentTime)

        if timeInterval <= 0 {
            return "now"
        }

        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours) hours \(minutes) minutes"
        } else if hours > 0 {
            return "\(hours) hours"
        } else {
            return "\(minutes) minutes"
        }
    }

    private var statusColor: Color {
        isStale ? .gray : status.color
    }

    private func startTimer() {
        // Update every minute to keep time display current
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                currentTime = Date()
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            TimeIcon(percentage: 35, sessionResetAt: Date().addingTimeInterval(2.5 * 3600), status: .safe, isLoading: false, isStale: false)
            TimeIcon(percentage: 65, sessionResetAt: Date().addingTimeInterval(1.5 * 3600), status: .warning, isLoading: false, isStale: false)
            TimeIcon(percentage: 92, sessionResetAt: Date().addingTimeInterval(0.5 * 3600), status: .critical, isLoading: false, isStale: false)
        }
        HStack(spacing: 20) {
            TimeIcon(percentage: 45, sessionResetAt: nil, status: .safe, isLoading: false, isStale: false)
            TimeIcon(percentage: 45, sessionResetAt: Date().addingTimeInterval(2 * 3600 + 30 * 60), status: .safe, isLoading: true, isStale: false)
            TimeIcon(percentage: 45, sessionResetAt: Date().addingTimeInterval(4 * 3600 + 5 * 60), status: .safe, isLoading: false, isStale: true)
        }
    }
    .padding()
}
