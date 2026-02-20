import SwiftUI

struct RouteMarkView: View {
    @EnvironmentObject var session: ClimbSessionManager
    
    @State private var selectedType: ClimbSessionManager.ClimbType = .boulder
    @State private var gradeIndex: Double = 3
    @State private var isStarred: Bool = false
    @State private var showConfirmation = false
    
    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let warmGray = Color(red: 0.50, green: 0.46, blue: 0.40)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)
    private let amberYellow = Color(red: 0.90, green: 0.65, blue: 0.20)
    
    private var availableTypes: [ClimbSessionManager.ClimbType] {
        session.scene.climbTypes
    }
    
    private var grades: [String] {
        session.gradesForType(selectedType)
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
                    // Type picker
                    HStack(spacing: 6) {
                        ForEach(availableTypes, id: \.self) { type in
                            Button {
                                selectedType = type
                                gradeIndex = min(gradeIndex, Double(session.gradesForType(type).count - 1))
                            } label: {
                                Text(type.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        selectedType == type
                                        ? forestGreen.opacity(0.8)
                                        : Color.white.opacity(0.08),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(selectedType == type ? .white : warmGray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Grade selector with Digital Crown
                    VStack(spacing: 2) {
                        Text("难度")
                            .font(.system(size: 9))
                            .foregroundStyle(warmGray)
                        Text(currentGrade)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(warmWhite)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: gradeIndex)
                    }
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
                        HStack(spacing: 4) {
                            Image(systemName: isStarred ? "star.fill" : "star")
                                .foregroundStyle(isStarred ? amberYellow : warmGray)
                                .font(.system(size: 12))
                            Text("好线")
                                .font(.system(size: 11))
                                .foregroundStyle(isStarred ? amberYellow : warmGray)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
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
            
            // Confirmation overlay
            if showConfirmation {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(forestGreen)
                        Text("+1 已记录")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(warmWhite)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showConfirmation)
        .onAppear {
            // Default to first available type
            if !availableTypes.contains(selectedType) {
                selectedType = availableTypes.first ?? .boulder
            }
        }
    }
    
    private func logWithStatus(_ status: ClimbSessionManager.CompletionStatus) {
        session.logRoute(type: selectedType, difficulty: currentGrade, status: status, starred: isStarred)
        isStarred = false
        
        showConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showConfirmation = false
        }
    }
}
