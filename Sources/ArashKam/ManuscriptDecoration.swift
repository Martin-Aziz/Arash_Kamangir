#if os(macOS)
import SwiftUI

/// Original vector identity: a tall bow, taut bowstring, and an eastward arrow.
/// No manuscript scan or third-party artwork is embedded in the application.
struct ArashMark: View {
    var color: Color = .accentColor
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var bow = Path()
            bow.move(to: CGPoint(x: w * 0.31, y: h * 0.12))
            bow.addQuadCurve(
                to: CGPoint(x: w * 0.31, y: h * 0.88),
                control: CGPoint(x: w * 0.01, y: h * 0.5))
            context.stroke(bow, with: .color(color), style:
                StrokeStyle(lineWidth: max(1.5, w * 0.07), lineCap: .round))

            var string = Path()
            string.move(to: CGPoint(x: w * 0.31, y: h * 0.12))
            string.addLine(to: CGPoint(x: w * 0.45, y: h * 0.5))
            string.addLine(to: CGPoint(x: w * 0.31, y: h * 0.88))
            context.stroke(string, with: .color(color.opacity(0.7)),
                style: StrokeStyle(lineWidth: max(0.8, w * 0.026)))

            var arrow = Path()
            arrow.move(to: CGPoint(x: w * 0.13, y: h * 0.5))
            arrow.addLine(to: CGPoint(x: w * 0.86, y: h * 0.5))
            context.stroke(arrow, with: .color(color),
                style: StrokeStyle(lineWidth: max(1.5, w * 0.055), lineCap: .round))

            var tip = Path()
            tip.move(to: CGPoint(x: w * 0.72, y: h * 0.36))
            tip.addLine(to: CGPoint(x: w * 0.95, y: h * 0.5))
            tip.addLine(to: CGPoint(x: w * 0.72, y: h * 0.64))
            tip.closeSubpath()
            context.fill(tip, with: .color(color))

            var fletch = Path()
            fletch.move(to: CGPoint(x: w * 0.13, y: h * 0.5))
            fletch.addLine(to: CGPoint(x: w * 0.23, y: h * 0.36))
            fletch.move(to: CGPoint(x: w * 0.13, y: h * 0.5))
            fletch.addLine(to: CGPoint(x: w * 0.23, y: h * 0.64))
            context.stroke(fletch, with: .color(color),
                style: StrokeStyle(lineWidth: max(1, w * 0.035)))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("آرش کمانگیر · Bow and arrow")
    }
}

struct ManuscriptRosette: View {
    let color: Color
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Ellipse()
                    .stroke(color.opacity(0.85), lineWidth: 1)
                    .frame(width: 5, height: 12)
                    .offset(y: -6)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            Circle().fill(color).frame(width: 4, height: 4)
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }
}

/// Double rules and corner rosettes reinterpret historical floral borders as
/// scalable vector ornament without obscuring or reproducing manuscript scans.
struct ManuscriptFrame: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke(color.opacity(0.55), lineWidth: 1)
                .padding(10)
            RoundedRectangle(cornerRadius: 3)
                .stroke(color.opacity(0.25), lineWidth: 0.6)
                .padding(17)
            VStack {
                HStack {
                    ManuscriptRosette(color: color)
                    Spacer()
                    ManuscriptRosette(color: color)
                }
                Spacer()
                HStack {
                    ManuscriptRosette(color: color)
                    Spacer()
                    ManuscriptRosette(color: color)
                }
            }
            .padding(12)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ManuscriptDivider: View {
    let color: Color
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().frame(height: 1).opacity(0.42)
            ManuscriptRosette(color: color)
            Rectangle().frame(height: 1).opacity(0.42)
        }
        .foregroundStyle(color)
        .accessibilityHidden(true)
    }
}

/// System-version-aware Liquid Glass: reserved for floating actions, never the
/// actual poem page, following Apple's distinction between chrome and content.
struct ReaderGlassChrome: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 17))
        } else {
            content
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
        }
    }
}
#endif
