import SwiftUI

/// I-9: Phone number login page
struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var phone = ""
    @State private var code = ""
    @State private var nickname = ""
    @State private var isRegistering = false
    @State private var codeSent = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var countdown = 0
    
    private var isPhoneValid: Bool {
        phone.count == 11 && phone.allSatisfy(\.isNumber)
    }
    
    var body: some View {
        ZStack {
            // Full-screen gradient background
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.15, blue: 0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    
                    // Logo section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(.green.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Image(systemName: "figure.climbing")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(.green)
                        }
                        
                        Text("TopOut")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("攀岩实时记录")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.bottom, 40)
                    
                    // Form section
                    VStack(spacing: 16) {
                        // Phone input
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .foregroundStyle(.green)
                                .frame(width: 20)
                            TextField("手机号", text: $phone)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .foregroundStyle(.white)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        
                        // Verification code input
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.green)
                                .frame(width: 20)
                            TextField("验证码", text: $code)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .foregroundStyle(.white)
                            
                            Button(action: sendCode) {
                                Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(isPhoneValid && countdown == 0 ? .green : .gray)
                            }
                            .disabled(!isPhoneValid || countdown > 0)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        
                        // Nickname (register mode)
                        if isRegistering {
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.green)
                                    .frame(width: 20)
                                TextField("昵称", text: $nickname)
                                    .textContentType(.nickname)
                                    .foregroundStyle(.white)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        
                        // Error message
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.top, 4)
                        }
                        
                        // Login button
                        Button(action: submit) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(isRegistering ? "注册" : "登录")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.green, Color(red: 0.1, green: 0.7, blue: 0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .foregroundStyle(.white)
                        }
                        .disabled(isLoading || !isPhoneValid || code.isEmpty || (isRegistering && nickname.isEmpty))
                        .opacity(isLoading || !isPhoneValid || code.isEmpty || (isRegistering && nickname.isEmpty) ? 0.5 : 1)
                        .padding(.top, 8)
                        
                        // Toggle register/login
                        Button(isRegistering ? "已有账号？登录" : "没有账号？注册") {
                            withAnimation(.easeInOut(duration: 0.3)) { isRegistering.toggle() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 28)
                    
                    Spacer().frame(height: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private func sendCode() {
        codeSent = true
        countdown = 60
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 { timer.invalidate() }
        }
    }
    
    private func submit() {
        // Test mode: code 888 bypasses backend
        if code == "888" {
            authService.isLoggedIn = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        Task {
            do {
                if isRegistering {
                    try await authService.register(phone: phone, code: code, nickname: nickname)
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
