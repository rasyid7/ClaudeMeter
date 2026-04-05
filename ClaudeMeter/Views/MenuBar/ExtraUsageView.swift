//
//  ExtraUsageView.swift
//  ClaudeMeter
//
//  Created by Claude on 2026-04-05.
//

import SwiftUI

/// View for displaying extra usage credits
struct ExtraUsageView: View {
    let extraUsage: ExtraUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(spacing: 8) {
                Image(systemName: "creditcard.fill")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("Extra Credits")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()
            }

            // Used credits amount (used_credits / 100)
            Text("$\(extraUsage.usedCredits / 100, specifier: "%.2f")")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.blue)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue)
                        .frame(width: geometry.size.width * min(extraUsage.utilization / 100, 1.0))
                }
            }
            .frame(height: 8)

            // Monthly limit info (both divided by 100 for cents → dollars)
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle")
                    .font(.caption)
                Text("$\(extraUsage.usedCredits / 100, specifier: "%.2f") of $\(Double(extraUsage.monthlyLimit) / 100, specifier: "%.2f") monthly limit")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Extra Credits: $\(extraUsage.usedCredits / 100, specifier: "%.2f") used of $\(Double(extraUsage.monthlyLimit) / 100, specifier: "%.2f") monthly limit")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ExtraUsageView(
            extraUsage: ExtraUsage(
                monthlyLimit: 2000,
                usedCredits: 354.0,  // $3.54
                utilization: 17.7
            )
        )
    }
    .padding()
    .frame(width: 320)
}
