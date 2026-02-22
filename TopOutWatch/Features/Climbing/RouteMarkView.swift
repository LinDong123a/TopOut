import SwiftUI

struct CompletionFlowView: View {
    @EnvironmentObject var session: ClimbSessionManager
    @Environment(\.dismiss) private var dismiss

    /// Callback: (status, difficulty, isStarred)
    var onComplete: (ClimbSessionManager.CompletionStatus, String, Bool) -> Void

    @State private var gradeIndex: Double = 3
    @State private var isStarred: Bool = false
    @State private var showGradePicker = false

    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)
    private let amberYellow = Color(red: 0.90, green: 0.65, blue: 0.20)

    private var grades: [String] {
        session.gradesForType(session.selectedClimbType)
    }

    private var currentGrade: String {
        let idx = min(max(Int(gradeIndex), 0), grades.count - 1)
        return grades.isEmpty ? "" : grades[idx]
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 8) {
                    // Current type label
                    Text(session.selectedClimbType.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(warmGray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08), in: Capsule())

                    // Grade selector — tap to pick
                    Button {
                        showGradePicker = true
                    } label: {
                        VStack(spacing: 2) {
                            Text("难度")
                                .font(.system(size: 9))
                                .foregroundStyle(warmGray)
                            HStack(spacing: 4) {
                                Text(currentGrade)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(warmWhite)
                                    .contentTransition(.numericText())
                                    .animation(.spring(response: 0.3), value: gradeIndex)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundStyle(warmGray)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .focusable()
                    .digitalCrownRotation(
                        $gradeIndex,
                        from: 0.0,
                        through: Double(max(grades.count - 1, 0)),
                        by: 1.0,
                        sensitivity: .medium,
                        isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )

                    // Star toggle
                    Button {
                        isStarred.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isStarred ? "star.fill" : "star")
                                .foregroundStyle(isStarred ? amberYellow : warmGray)
                                .font(.system(size: 16))
                            Text("好线")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(isStarred ? amberYellow : warmGray)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            isStarred ? amberYellow.opacity(0.15) : Color.white.opacity(0.06),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)

                    // Completion buttons — 2x2 grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 6),
                        GridItem(.flexible(), spacing: 6)
                    ], spacing: 6) {
                        ForEach(ClimbSessionManager.CompletionStatus.allCases, id: \.self) { status in
                            Button {
                                logWithStatus(status)
                            } label: {
                                VStack(spacing: 2) {
                                    Text(status.emoji)
                                        .font(.system(size: 16))
                                    Text(status.label)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(warmWhite)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
                .foregroundStyle(warmGray)
            }
        }
        .sheet(isPresented: $showGradePicker) {
            gradePickerSheet
        }
    }

    // MARK: - Grade Picker Sheet

    private var gradePickerSheet: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(grades.enumerated()), id: \.offset) { idx, grade in
                    Button {
                        gradeIndex = Double(idx)
                        showGradePicker = false
                    } label: {
                        HStack {
                            Text(grade)
                                .font(.system(size: 16, weight: idx == Int(gradeIndex) ? .bold : .regular))
                                .foregroundStyle(idx == Int(gradeIndex) ? forestGreen : warmWhite)
                            Spacer()
                            if idx == Int(gradeIndex) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(forestGreen)
                            }
                        }
                    }
                    .id(idx)
                }
            }
            .onAppear {
                proxy.scrollTo(Int(gradeIndex), anchor: .center)
            }
        }
        .navigationTitle("选择难度")
    }

    // MARK: - Actions

    private func logWithStatus(_ status: ClimbSessionManager.CompletionStatus) {
        onComplete(status, currentGrade, isStarred)
        isStarred = false
        dismiss()
    }
}
