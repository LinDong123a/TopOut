import SwiftUI

/// I-6: Privacy settings before starting a climb — compact horizontal layout
struct ClimbPrivacySettingsView: View {
    @Binding var settings: PrivacySettings

    var body: some View {
        HStack(spacing: 12) {
            // 场馆大屏可见
            HStack(spacing: 8) {
                Image(systemName: settings.isVisible ? "eye" : "eye.slash")
                    .font(.caption)
                    .foregroundStyle(settings.isVisible ? .green : .gray)
                Text("大屏可见")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textSecondary)
                Toggle("", isOn: $settings.isVisible)
                    .labelsHidden()
                    .scaleEffect(0.75)
                    .frame(width: 40)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

            // 匿名模式
            HStack(spacing: 8) {
                Image(systemName: settings.isAnonymous ? "person.fill.questionmark" : "person.fill")
                    .font(.caption)
                    .foregroundStyle(settings.isAnonymous ? .orange : .gray)
                Text("匿名")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textSecondary)
                Toggle("", isOn: $settings.isAnonymous)
                    .labelsHidden()
                    .scaleEffect(0.75)
                    .frame(width: 40)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .opacity(settings.isVisible ? 1 : 0.4)
            .disabled(!settings.isVisible)
        }
        .animation(.easeInOut(duration: 0.2), value: settings.isVisible)
        .onChange(of: settings) { _, newValue in
            newValue.save()
        }
    }
}

#Preview {
    ClimbPrivacySettingsView(settings: .constant(.default))
        .padding()
}
