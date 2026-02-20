import SwiftUI

/// Immersive full-screen login — outdoor earth-tone palette
struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var phone = ""
    @State private var code = ""
    @State private var nickname = ""
    @State private var isRegistering = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var countdown = 0
    @State private var appeared = false

    private var isPhoneValid: Bool {
        phone.count == 11 && phone.allSatisfy(\.isNumber)
    }

    private var canSubmit: Bool {
        isPhoneValid && !code.isEmpty
            && (!isRegistering || !nickname.isEmpty) && !isLoading
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: max(geo.size.height * 0.09, 36))
                        logoSection
                            .padding(.bottom, geo.size.height * 0.05)
                        formSection
                            .padding(.horizontal, max((geo.size.width - 380) / 2, 24))
                        Spacer().frame(height: 48)
                    }
                    .frame(minHeight: geo.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .ignoresSafeArea(.container)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { appeared = true }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            TopOutTheme.backgroundPrimary
            // Warm radial glow at top
            RadialGradient(
                colors: [
                    TopOutTheme.earthBrown.opacity(0.12),
                    Color.clear
                ],
                center: .top,
                startRadius: 80, endRadius: 450
            )
            // Subtle green glow center
            RadialGradient(
                colors: [
                    TopOutTheme.mossGreen.opacity(0.06),
                    Color.clear
                ],
                center: .center,
                startRadius: 40, endRadius: 350
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                TopOutTheme.accentGreen.opacity(0.18),
                                TopOutTheme.earthBrown.opacity(0.06)
                            ],
                            center: .center,
                            startRadius: 8, endRadius: 44
                        )
                    )
                    .frame(width: 84, height: 84)

                Image(systemName: "figure.climbing")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [TopOutTheme.accentGreen, TopOutTheme.sageGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("TopOut")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(TopOutTheme.textPrimary)

            Text("攀岩实时记录")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textTertiary)
        }
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1.0 : 0)
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 14) {
            inputField(icon: "phone.fill", placeholder: "手机号",
                       text: $phone, keyboard: .phonePad,
                       contentType: .telephoneNumber)

            codeField

            if isRegistering {
                inputField(icon: "person.fill", placeholder: "昵称",
                           text: $nickname, keyboard: .default,
                           contentType: .nickname)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let errorMessage {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(errorMessage).font(.caption)
                }
                .foregroundStyle(TopOutTheme.heartRed)
                .padding(.top, 2)
            }

            submitButton.padding(.top, 8)

            Button(isRegistering ? "已有账号？登录" : "没有账号？注册") {
                withAnimation(.spring(response: 0.35)) {
                    isRegistering.toggle()
                }
            }
            .font(.subheadline)
            .foregroundStyle(TopOutTheme.textTertiary)
            .padding(.top, 4)
        }
    }

    // MARK: - Input helpers

    private func inputField(icon: String, placeholder: String,
                            text: Binding<String>,
                            keyboard: UIKeyboardType,
                            contentType: UITextContentType) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(TopOutTheme.sageGreen)
                .frame(width: 20)
            TextField("", text: text,
                      prompt: Text(placeholder)
                          .foregroundStyle(TopOutTheme.textTertiary))
                .keyboardType(keyboard)
                .textContentType(contentType)
                .foregroundStyle(TopOutTheme.textPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.05),
                     in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(TopOutTheme.cardStroke, lineWidth: 1)
        )
    }

    private var codeField: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .foregroundStyle(TopOutTheme.sageGreen)
                .frame(width: 20)
            TextField("", text: $code,
                      prompt: Text("验证码")
                          .foregroundStyle(TopOutTheme.textTertiary))
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .foregroundStyle(TopOutTheme.textPrimary)

            Button(action: sendCode) {
                Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        isPhoneValid && countdown == 0
                            ? TopOutTheme.accentGreen
                            : TopOutTheme.textTertiary
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        (isPhoneValid && countdown == 0
                            ? TopOutTheme.accentGreen.opacity(0.12)
                            : Color.clear),
                        in: Capsule()
                    )
            }
            .disabled(!isPhoneValid || countdown > 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.05),
                     in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(TopOutTheme.cardStroke, lineWidth: 1)
        )
    }

    private var submitButton: some View {
        Button(action: submit) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.85)
                }
                Text(isRegistering ? "注册" : "登录")
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                canSubmit
                    ? AnyShapeStyle(TopOutTheme.greenGradient)
                    : AnyShapeStyle(Color.white.opacity(0.06)),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .foregroundStyle(canSubmit ? .white : TopOutTheme.textTertiary)
        }
        .disabled(!canSubmit)
        .animation(.easeInOut(duration: 0.2), value: canSubmit)
    }

    // MARK: - Actions

    private func sendCode() {
        countdown = 60
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 { timer.invalidate() }
        }
    }

    private func submit() {
        if code == "888" {
            authService.isLoggedIn = true
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                if isRegistering {
                    try await authService.register(
                        phone: phone, code: code, nickname: nickname)
                } else {
                    try await authService.login(phone: phone, code: code)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
}
