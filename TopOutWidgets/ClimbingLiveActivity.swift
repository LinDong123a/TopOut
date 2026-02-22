import SwiftUI
import WidgetKit
import ActivityKit

struct ClimbingLiveActivity: Widget {

    // TopOutTheme colors (hardcoded — widget cannot import app module)
    private static let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private static let heartRed = Color(red: 0.85, green: 0.25, blue: 0.20)
    private static let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private static let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private static let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClimbingActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.climbing")
                            .font(.system(size: 16))
                            .foregroundStyle(Self.forestGreen)
                        Text(context.attributes.startTime, style: .timer)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("完攀")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.completionText)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Self.forestGreen)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.difficulties.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(Array(context.state.difficultyPills.enumerated()), id: \.offset) { _, pill in
                                HStack(spacing: 2) {
                                    Text(pill.difficulty)
                                        .fontWeight(.semibold)
                                    Text("×\(pill.count)")
                                }
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Self.forestGreen.opacity(0.2), in: Capsule())
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "figure.climbing")
                    .foregroundStyle(Self.forestGreen)
            } compactTrailing: {
                Text("\(context.state.totalCount)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(Self.forestGreen)
            } minimal: {
                Image(systemName: "figure.climbing")
                    .foregroundStyle(Self.forestGreen)
            }
        }
    }

    // MARK: - Lock Screen Layout

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<ClimbingActivityAttributes>) -> some View {
        VStack(spacing: 10) {
            // Top row: icon + timer | completion ratio
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "figure.climbing")
                        .font(.title3)
                        .foregroundStyle(Self.forestGreen)

                    Text(context.attributes.startTime, style: .timer)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(Self.warmWhite)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("完攀")
                        .font(.caption2)
                        .foregroundStyle(Self.warmGray)
                    Text(context.state.completionText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Self.forestGreen)
                }
            }

            // Bottom row: difficulty pills
            if !context.state.difficulties.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(context.state.difficultyPills.enumerated()), id: \.offset) { _, pill in
                        HStack(spacing: 3) {
                            Text(pill.difficulty)
                                .fontWeight(.semibold)
                            Text("×\(pill.count)")
                        }
                        .font(.caption)
                        .foregroundStyle(Self.warmWhite)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Self.forestGreen.opacity(0.2), in: Capsule())
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Self.bgColor)
    }
}
