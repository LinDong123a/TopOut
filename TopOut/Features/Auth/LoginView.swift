import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var phone = ""
    @State private var code = ""
    @State private var nickname = ""
    @State private var isRegistering = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var countdown = 0
    @State private var logoAppeared = false
    @State private var formAppeared = false
    @State private var buttonPressed = false

    private var isPhoneValid: Bool {
        phone.count == 11 && phone.allSatisfy(\.isNumber)
    }

    private var canSubmit: Bool {
        isPhoneValid && !code.isEmpty && (!isRegistering || !nickname.isEmpty) && !isLoading
    }

    var body: some View {
        ZStack {
            // Background fills entire screen
            TopOutTheme.backgroundPrimary
                .ignoresSafeArea()
            
            RadialGradient(
                colors: [TopOutTheme.earthBrown.opacity(0.12), Color.clear],
                center: .top, startRadius: 80, endRadius: 450
            )
            .ignoresSafeArea()
            
            // Content - no ScrollView, fixed layout
            VStack(spacing: 0) {
                Spacer()
                
                // Logo
                VStack(spacing: 14) {
                    LogoView(size: 140)

                    Text("攀岩实时记录")
                        .font(.subheadline)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
                .scaleEffect(logoAppeared ? 1.0 : 0.5)
                .opacity(logoAppeared ? 1.0 : 0)
                
                Spacer().frame(height: 40)
                
                // Form
                VStack(spacing: 14) {
                    // Phone
                    inputField(icon: "phone.fill", placeholder: "手机号", text: $phone, keyboard: .phonePad)
                    
                    // Code
                    HStack(spacing: 14) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(TopOutTheme.sageGreen)
                            .frame(width: 20)
                        TextField("", text: $code,
                                  prompt: Text("验证码").foregroundStyle(TopOutTheme.textTertiary))
                            .keyboardType(.numberPad)
                            .foregroundStyle(TopOutTheme.textPrimary)
                        
                        Button(action: sendCode) {
                            Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isPhoneValid && countdown == 0 ? TopOutTheme.accentGreen : TopOutTheme.textTertiary)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(
                                    isPhoneValid && countdown == 0 ? TopOutTheme.accentGreen.opacity(0.12) : Color.clear,
                                    in: Capsule()
                                )
                        }
                        .disabled(!isPhoneValid || countdown > 0)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 15)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(TopOutTheme.cardStroke, lineWidth: 1))
                    
                    // Nickname
                    if isRegistering {
                        inputField(icon: "person.fill", placeholder: "昵称", text: $nickname, keyboard: .default)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // Error
                    if let errorMessage {
                        HStack(spacing: 5) {
                            Image(systemName: "exclamationmark.circle.fill").font(.caption)
                            Text(errorMessage).font(.caption)
                        }
                        .foregroundStyle(TopOutTheme.heartRed)
                        .transition(.opacity)
                    }
                    
                    // Submit
                    Button(action: submit) {
                        HStack(spacing: 8) {
                            if isLoading { ProgressView().tint(.white).scaleEffect(0.85) }
                            Text(isRegistering ? "注册" : "登录")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            canSubmit ? AnyShapeStyle(TopOutTheme.greenGradient) : AnyShapeStyle(Color.white.opacity(0.06)),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(canSubmit ? .white : TopOutTheme.textTertiary)
                    }
                    // .disabled(!canSubmit) // Dev mode: always enabled
                    .scaleEffect(buttonPressed ? 0.95 : 1.0)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in buttonPressed = true }
                            .onEnded { _ in buttonPressed = false }
                    )
                    .padding(.top, 6)
                    
                    // Toggle
                    Button(isRegistering ? "已有账号？登录" : "没有账号？注册") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { isRegistering.toggle() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(TopOutTheme.textTertiary)
                }
                .padding(.horizontal, 28)
                .opacity(formAppeared ? 1 : 0)
                .offset(y: formAppeared ? 0 : 20)
                
                Spacer()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { logoAppeared = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) { formAppeared = true }
        }
    }
    
    private func inputField(icon: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(TopOutTheme.sageGreen)
                .frame(width: 20)
            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(TopOutTheme.textTertiary))
                .keyboardType(keyboard)
                .foregroundStyle(TopOutTheme.textPrimary)
        }
        .padding(.horizontal, 18).padding(.vertical, 15)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(TopOutTheme.cardStroke, lineWidth: 1))
    }
    
    private func sendCode() {
        countdown = 60
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 { timer.invalidate() }
        }
    }
    
    private func submit() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // Dev mode: tap login to enter directly
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { authService.isLoggedIn = true }
        return
        // --- production code below ---
        isLoading = true; errorMessage = nil
        Task {
            do {
                if isRegistering {
                    try await authService.register(phone: phone, code: code, nickname: nickname)
                } else {
                    try await authService.login(phone: phone, code: code)
                }
            } catch {
                withAnimation { errorMessage = error.localizedDescription }
            }
            isLoading = false
        }
    }
}
