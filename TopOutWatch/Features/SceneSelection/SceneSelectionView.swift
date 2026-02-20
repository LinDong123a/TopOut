import SwiftUI

struct SceneSelectionView: View {
    @EnvironmentObject var session: ClimbSessionManager
    
    private let forestGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    private let rockBrown = Color(red: 0.60, green: 0.45, blue: 0.30)
    private let warmWhite = Color(red: 0.94, green: 0.91, blue: 0.86)
    private let bgColor = Color(red: 0.08, green: 0.07, blue: 0.06)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 10) {
                Text("选择场景")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(warmWhite.opacity(0.7))
                
                Button { session.selectScene(.indoor) } label: {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.title3)
                        Text("室内 🏢")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(forestGreen)
                
                Button { session.selectScene(.outdoor) } label: {
                    HStack {
                        Image(systemName: "mountain.2.fill")
                            .font(.title3)
                        Text("户外 🏔️")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(rockBrown)
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
    }
}
