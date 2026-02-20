import SwiftUI

/// I-6: Privacy settings before starting a climb
struct ClimbPrivacySettingsView: View {
    @Binding var settings: PrivacySettings
    
    var body: some View {
        VStack(spacing: 16) {
            // Visibility toggle
            HStack {
                Image(systemName: settings.isVisible ? "eye" : "eye.slash")
                    .font(.title3)
                    .foregroundStyle(settings.isVisible ? .green : .gray)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("场馆大屏可见")
                        .font(.subheadline.weight(.medium))
                    Text(settings.isVisible ? "其他人可以在大屏看到你" : "不会出现在大屏上")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.isVisible)
                    .labelsHidden()
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Anonymous toggle
            if settings.isVisible {
                HStack {
                    Image(systemName: settings.isAnonymous ? "person.fill.questionmark" : "person.fill")
                        .font(.title3)
                        .foregroundStyle(settings.isAnonymous ? .orange : .blue)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("匿名模式")
                            .font(.subheadline.weight(.medium))
                        Text(settings.isAnonymous ? "显示为「攀岩者 #XXXX」" : "显示你的昵称和头像")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.isAnonymous)
                        .labelsHidden()
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
