import SwiftUI

struct CheckInAlertView: View {
    let gymName: String
    let onCheckIn: () -> Void
    let onDismiss: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 20) {
                // Header emoji
                Text("👋")
                    .font(.system(size: 48))
                
                // Title
                VStack(spacing: 6) {
                    Text("你到了")
                        .font(.title3)
                        .foregroundStyle(TopOutTheme.textSecondary)
                    Text(gymName)
                        .font(.title.weight(.bold))
                        .foregroundStyle(TopOutTheme.textPrimary)
                        .multilineTextAlignment(.center)
                }
                
                // Gym info
                HStack(spacing: 16) {
                    Label("50+ 线路", systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textSecondary)
                    Label("10:00-22:00", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
                
                Divider()
                    .background(TopOutTheme.cardStroke)
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: onCheckIn) {
                        HStack {
                            Text("✅")
                            Text("打卡签到")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(TopOutTheme.accentGreen, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                    
                    Button(action: onDismiss) {
                        Text("稍后再说")
                            .font(.subheadline)
                            .foregroundStyle(TopOutTheme.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }
            .padding(28)
            .background(TopOutTheme.backgroundElevated, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(TopOutTheme.cardStroke, lineWidth: 1)
            )
            .padding(.horizontal, 40)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

#Preview {
    CheckInAlertView(gymName: "岩时攀岩馆（望京店）", onCheckIn: {}, onDismiss: {})
}
