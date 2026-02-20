import SwiftUI

/// TopOut App Logo — Shield badge with mountain peaks and stylized "T"
/// Use `LogoView(size: 1024)` and screenshot from Preview to export AppIcon
struct LogoView: View {
    var size: CGFloat = 200

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let cx = w / 2

            // ── Shield / Badge shape ──
            let shieldPath = shieldShape(in: CGRect(origin: .zero, size: canvasSize))

            // Background fill
            context.fill(shieldPath, with: .color(Color(red: 0.10, green: 0.09, blue: 0.07)))

            // Subtle inner glow at top
            let glowGradient = Gradient(colors: [
                Color(red: 0.18, green: 0.16, blue: 0.13),
                Color(red: 0.10, green: 0.09, blue: 0.07)
            ])
            context.fill(shieldPath, with: .radialGradient(
                glowGradient,
                center: CGPoint(x: cx, y: h * 0.3),
                startRadius: 0,
                endRadius: h * 0.6
            ))

            // ── Mountain peaks ──
            // Left peak (shorter)
            let leftPeak = Path { p in
                p.move(to: CGPoint(x: w * 0.12, y: h * 0.72))
                p.addLine(to: CGPoint(x: w * 0.35, y: h * 0.30))
                p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.50))
                p.addLine(to: CGPoint(x: w * 0.12, y: h * 0.72))
                p.closeSubpath()
            }

            // Right peak (taller — main peak)
            let rightPeak = Path { p in
                p.move(to: CGPoint(x: w * 0.38, y: h * 0.72))
                p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.22))
                p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.72))
                p.closeSubpath()
            }

            // Mountain gradients (darker at base, brighter at peak)
            let mountainGradient = Gradient(colors: [
                TopOutTheme.accentGreen,
                TopOutTheme.mossGreen.opacity(0.7)
            ])

            context.fill(rightPeak, with: .linearGradient(
                mountainGradient,
                startPoint: CGPoint(x: cx, y: h * 0.22),
                endPoint: CGPoint(x: cx, y: h * 0.72)
            ))

            let leftMountainGradient = Gradient(colors: [
                TopOutTheme.sageGreen.opacity(0.8),
                TopOutTheme.mossGreen.opacity(0.5)
            ])
            context.fill(leftPeak, with: .linearGradient(
                leftMountainGradient,
                startPoint: CGPoint(x: w * 0.35, y: h * 0.30),
                endPoint: CGPoint(x: w * 0.35, y: h * 0.72)
            ))

            // ── Stylized "T" — merged with summit ──
            // The T crossbar sits at the summit of the right peak
            // The T stem extends down as a bold vertical through the mountain

            let stemWidth = w * 0.065
            let crossbarWidth = w * 0.30
            let crossbarHeight = h * 0.045

            // T stem (vertical line from summit downward)
            let stemRect = CGRect(
                x: w * 0.62 - stemWidth / 2,
                y: h * 0.22,
                width: stemWidth,
                height: h * 0.35
            )
            let stemPath = RoundedRectangle(cornerRadius: stemWidth * 0.3)
                .path(in: stemRect)

            // T crossbar (horizontal bar at the top)
            let crossbarRect = CGRect(
                x: w * 0.62 - crossbarWidth / 2,
                y: h * 0.20 - crossbarHeight / 2,
                width: crossbarWidth,
                height: crossbarHeight
            )
            let crossbarPath = RoundedRectangle(cornerRadius: crossbarHeight * 0.4)
                .path(in: crossbarRect)

            // Draw T in warm off-white
            let tColor = Color(red: 0.94, green: 0.91, blue: 0.86)
            context.fill(stemPath, with: .color(tColor))
            context.fill(crossbarPath, with: .color(tColor))

            // ── Base arc — rock foundation ──
            let basePath = Path { p in
                p.move(to: CGPoint(x: w * 0.18, y: h * 0.74))
                p.addQuadCurve(
                    to: CGPoint(x: w * 0.82, y: h * 0.74),
                    control: CGPoint(x: cx, y: h * 0.80)
                )
            }
            context.stroke(
                basePath,
                with: .color(TopOutTheme.rockBrown.opacity(0.6)),
                lineWidth: w * 0.012
            )

            // ── "TOPOUT" text below mountains ──
            let fontSize = w * 0.085
            let text = Text("TOPOUT")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(TopOutTheme.textPrimary)
                .tracking(fontSize * 0.35)

            context.draw(
                context.resolve(text),
                at: CGPoint(x: cx, y: h * 0.86),
                anchor: .center
            )

            // ── Shield border stroke ──
            context.stroke(
                shieldPath,
                with: .color(TopOutTheme.accentGreen.opacity(0.5)),
                lineWidth: w * 0.018
            )

            // Secondary outer glow stroke
            context.stroke(
                shieldPath,
                with: .color(Color.white.opacity(0.06)),
                lineWidth: w * 0.006
            )

        }
        .frame(width: size, height: size)
    }

    /// Rounded shield / badge shape
    private func shieldShape(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let inset: CGFloat = w * 0.04

        return Path { p in
            let top = inset
            let left = inset
            let right = w - inset
            let radius = w * 0.12

            // Top-left corner
            p.move(to: CGPoint(x: left + radius, y: top))
            // Top edge
            p.addLine(to: CGPoint(x: right - radius, y: top))
            // Top-right corner
            p.addQuadCurve(
                to: CGPoint(x: right, y: top + radius),
                control: CGPoint(x: right, y: top)
            )
            // Right edge
            p.addLine(to: CGPoint(x: right, y: h * 0.60))
            // Bottom-right curve (shield point)
            p.addQuadCurve(
                to: CGPoint(x: w / 2, y: h - inset),
                control: CGPoint(x: right, y: h * 0.85)
            )
            // Bottom-left curve (shield point)
            p.addQuadCurve(
                to: CGPoint(x: left, y: h * 0.60),
                control: CGPoint(x: left, y: h * 0.85)
            )
            // Left edge
            p.addLine(to: CGPoint(x: left, y: top + radius))
            // Top-left corner
            p.addQuadCurve(
                to: CGPoint(x: left + radius, y: top),
                control: CGPoint(x: left, y: top)
            )
            p.closeSubpath()
        }
    }
}

// MARK: - Previews

#Preview("Logo — App Icon Size") {
    LogoView(size: 1024)
        .background(.black)
}

#Preview("Logo — Small") {
    LogoView(size: 120)
        .background(.black)
}

#Preview("Logo — Login Size") {
    LogoView(size: 200)
        .background(TopOutTheme.backgroundPrimary)
}
