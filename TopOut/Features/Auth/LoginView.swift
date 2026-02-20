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
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Logo
                VStack(spacing: 12) {
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                    Text("TopOut")
                        .font(.largeTitle.bold())
                    Text("攀岩实时记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Form
                VStack(spacing: 16) {
                    // Phone
                    HStack {
                        Image(systemName: "phone")
                            .foregroundStyle(.secondary)
                        TextField("手机号", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Verification code
                    HStack {
                        Image(systemName: "lock")
                            .foregroundStyle(.secondary)
                        TextField("验证码", text: $code)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                        
                        Button(action: sendCode) {
                            Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                                .font(.caption)
                        }
                        .disabled(!isPhoneValid || countdown > 0)
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Nickname (register mode)
                    if isRegistering {
                        HStack {
                            Image(systemName: "person")
                                .foregroundStyle(.secondary)
                            TextField("昵称", text: $nickname)
                                .textContentType(.nickname)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    // Login / Register button
                    Button(action: submit) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isRegistering ? "注册" : "登录")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                        .font(.headline)
                    }
                    .disabled(isLoading || !isPhoneValid || code.isEmpty || (isRegistering && nickname.isEmpty))
                    
                    Button(isRegistering ? "已有账号？登录" : "没有账号？注册") {
                        withAnimation { isRegistering.toggle() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    private func sendCode() {
        // In MVP, we just start a countdown. Backend sends SMS.
        codeSent = true
        countdown = 60
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 { timer.invalidate() }
        }
    }
    
    private func submit() {
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
