import SwiftUI

/// ViewModifier that overlays the cheer celebration effect
struct CheerCelebrationModifier: ViewModifier {
    @Binding var isPresented: Bool
    var fromUser: String
    
    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                CelebrationView(fromUser: fromUser, isPresented: $isPresented)
                    .transition(.opacity)
            }
        }
    }
}

extension View {
    func cheerCelebration(isPresented: Binding<Bool>, fromUser: String) -> some View {
        modifier(CheerCelebrationModifier(isPresented: isPresented, fromUser: fromUser))
    }
}
