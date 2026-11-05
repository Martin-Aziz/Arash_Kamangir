#if os(macOS)
import SwiftUI

/// Editable manuscript designs inspired by tazhib, sar-lawh illuminated
/// headpieces and tash'ir floral margins. All paths are original vector art.
/// These are genuinely different ART STYLES; ReaderAppearance continues to
/// control the opaque paper and foreground for contrast and accessibility.
enum ManuscriptTemplate: String, CaseIterable, Identifiable {
    case royalLapis
    case shirazGarden
    case moonlitDiwan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .royalLapis: return "Royal Lapis · لاجورد"
        case .shirazGarden: return "Shiraz Garden · باغ شیراز"
        case .moonlitDiwan: return "Moonlit Divan · مهتاب"
        }
    }

    var subtitle: String {
        switch self {
        case .royalLapis: return "Gold arches and lapis illumination"
        case .shirazGarden: return "Roses, vines and jade blossoms"
        case .moonlitDiwan: return "Midnight blue, stars and silver-gold"
        }
    }

    var pigment: Color {
        switch self {
        case .royalLapis: return Color(red: 0.08, green: 0.20, blue: 0.43)
        case .shirazGarden: return Color(red: 0.19, green: 0.40, blue: 0.30)
        case .moonlitDiwan: return Color(red: 0.07, green: 0.13, blue: 0.28)
        }
    }

    var pigmentLight: Color {
        switch self {
        case .royalLapis: return Color(red: 0.21, green: 0.40, blue: 0.63)
        case .shirazGarden: return Color(red: 0.42, green: 0.62, blue: 0.45)
        case .moonlitDiwan: return Color(red: 0.22, green: 0.34, blue: 0.55)
        }
    }

    var metal: Color {
        switch self {
        case .royalLapis: return Color(red: 0.79, green: 0.60, blue: 0.27)
        case .shirazGarden: return Color(red: 0.73, green: 0.56, blue: 0.31)
        case .moonlitDiwan: return Color(red: 0.78, green: 0.72, blue: 0.52)
        }
    }

    var blossom: Color {
        switch self {
        case .royalLapis: return Color(red: 0.73, green: 0.31, blue: 0.37)
        case .shirazGarden: return Color(red: 0.70, green: 0.37, blue: 0.43)
        case .moonlitDiwan: return Color(red: 0.69, green: 0.64, blue: 0.84)
        }
    }

    var leaf: Color {
        switch self {
        case .royalLapis: return Color(red: 0.25, green: 0.51, blue: 0.41)
        case .shirazGarden: return Color(red: 0.22, green: 0.45, blue: 0.31)
        case .moonlitDiwan: return Color(red: 0.45, green: 0.58, blue: 0.60)
        }
    }
}

/// Illuminated sar-lawh (سرلوح), with layered pointed arch, tiny starwork,
/// stylised roses and symmetrical gold arabesques. Text does not enter Canvas.
struct PersianIlluminatedHeadpiece: View {
    let template: ManuscriptTemplate
    var compact = false

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: true) { context, size in
            let width = size.width
            let height = size.height
            let inset: CGFloat = compact ? 5 : 12
            let bounds = CGRect(x: inset, y: inset, width: width - inset * 2,
                                height: height - inset * 2)
            let base = Path(roundedRect: bounds, cornerRadius: 3)
            context.fill(base, with: .color(template.pigment))
            context.stroke(base, with: .color(template.metal), lineWidth: 3)

            let inner = bounds.insetBy(dx: 8, dy: 8)
            context.stroke(Path(roundedRect: inner, cornerRadius: 2),
                           with: .color(template.metal.opacity(0.8)), lineWidth: 1)

            // Pointed, stepped central arch is the defining manuscript element.
            for layer in 0..<4 {
                let dx = CGFloat(layer) * 11
                let dy = CGFloat(layer) * 11
                let arch = ManuscriptDrawing.arch(
                    CGRect(x: width * 0.20 + dx,
                           y: height * 0.19 + dy,
                           width: width * 0.60 - dx * 2,
                           height: height * 0.72 - dy * 1.3))
                context.fill(arch, with: .color(layer.isMultiple(of: 2)
                            ? template.pigmentLight : template.pigment))
                context.stroke(arch, with: .color(template.metal),
                               lineWidth: layer == 0 ? 2.5 : 0.8)
            }

            // A dense, repeated khatai-inspired floral lattice, deliberately
            // confined to the headpiece, outside the selectable verse area.
            let columns = max(4, compact ? 7 : 11)
            let rows = compact ? 3 : 5
            for row in 0..<rows {
                for col in 0..<columns {
                    let cx = bounds.minX + bounds.width * (CGFloat(col) + 0.5)
                        / CGFloat(columns)
                    let cy = bounds.minY + bounds.height * (CGFloat(row) + 0.5)
                        / CGFloat(rows)
                    let nearCenter = abs(cx - width / 2) < width * 0.20
                    let radius: CGFloat = nearCenter ? 3.0 : 4.8
                    ManuscriptDrawing.flower(
                        context, center: CGPoint(x: cx, y: cy),
                        radius: radius, petals: 8,
                        petalColor: row.isMultiple(of: 2) ? template.metal
                            : template.blossom,
                        centerColor: template.metal)
                }
            }

            // Two small counterbalanced medallions along each half.
            for side in [-1.0, 1.0] {
                for level in 0..<3 {
                    let point = CGPoint(
                        x: width / 2 + CGFloat(side) * width * 0.33,
                        y: height * (0.30 + CGFloat(level) * 0.21))
                    ManuscriptDrawing.rosette(context, center: point,
                         radius: compact ? 10 : 17,
                         fill: template.pigmentLight, stroke: template.metal,
                         accent: template.blossom)
                }
            }

            ManuscriptDrawing.rosette(context,
                center: CGPoint(x: width / 2, y: height * 0.44),
                radius: compact ? 25 : 41,
                fill: template.pigmentLight,
                stroke: template.metal, accent: template.blossom)
        }
        .frame(height: compact ? 108 : 206)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Decorative page edges live in reserved margins. Artwork does not stretch
/// a scanned image, trap mouse input, or interfere with VoiceOver reading.
struct PersianIlluminatedFrame: View {
    let template: ManuscriptTemplate
    var ornate: Bool = true

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let richMargins = ornate && width >= 545

            Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                let outer = CGRect(x: 10, y: 10, width: size.width - 20,
                                   height: size.height - 20)
                let inner = outer.insetBy(dx: richMargins ? 24 : 8,
                                         dy: richMargins ? 24 : 8)
                context.stroke(Path(roundedRect: outer, cornerRadius: 3),
                               with: .color(template.metal), lineWidth: 1.5)
                context.stroke(Path(roundedRect: outer.insetBy(dx: 5, dy: 5),
                                    cornerRadius: 3),
                               with: .color(template.pigment), lineWidth: 1.2)
                context.stroke(Path(roundedRect: inner, cornerRadius: 2),
                               with: .color(template.metal.opacity(0.8)),
                               lineWidth: 0.8)

                if richMargins {
                    // Two flowing floral vines with actual repeating flowers,
                    // leaves and small medallions, not a plain rectangular rule.
                    for side in [0, 1] {
                        let x = side == 0 ? outer.minX + 15 : outer.maxX - 15
                        ManuscriptDrawing.vine(context, x: x,
                            top: outer.minY + 40, bottom: outer.maxY - 40,
                            side: side == 0 ? 1 : -1, template: template)
                    }

                    // Upper and lower floral rules visually join the margins.
                    for x in stride(from: outer.minX + 58,
                                    through: max(outer.minX + 58, outer.maxX - 58),
                                    by: 44.0) {
                        ManuscriptDrawing.flower(context,
                            center: CGPoint(x: x, y: outer.minY + 17),
                            radius: 4.8, petals: 6,
                            petalColor: template.blossom,
                            centerColor: template.metal)
                        ManuscriptDrawing.flower(context,
                            center: CGPoint(x: x, y: outer.maxY - 17),
                            radius: 4.8, petals: 6,
                            petalColor: template.blossom,
                            centerColor: template.metal)
                    }
                }

                for x in [outer.minX + 12, outer.maxX - 12] {
                    for y in [outer.minY + 12, outer.maxY - 12] {
                        ManuscriptDrawing.rosette(context,
                            center: CGPoint(x: x, y: y),
                            radius: richMargins ? 10 : 6,
                            fill: template.pigment,
                            stroke: template.metal,
                            accent: template.blossom)
                    }
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

enum ManuscriptDrawing {
    static func arch(_ rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX + rect.width * 0.10,
                             y: rect.minY + rect.height * 0.13))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.maxX - rect.width * 0.10,
                             y: rect.minY + rect.height * 0.13))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    static func flower(_ ctx: GraphicsContext, center: CGPoint,
                       radius: CGFloat, petals: Int,
                       petalColor: Color, centerColor: Color) {
        let count = max(3, petals)
        for index in 0..<count {
            let angle = Double(index) * 2 * Double.pi / Double(count)
            let direction = CGVector(dx: CGFloat(cos(angle)),
                                     dy: CGFloat(sin(angle)))
            let tangent = CGVector(dx: -direction.dy, dy: direction.dx)
            var petal = Path()
            petal.move(to: center)
            let tip = CGPoint(x: center.x + direction.dx * radius * 2.1,
                              y: center.y + direction.dy * radius * 2.1)
            petal.addQuadCurve(to: tip,
                control: CGPoint(x: center.x + tangent.dx * radius * 0.7
                    + direction.dx * radius,
                                 y: center.y + tangent.dy * radius * 0.7
                    + direction.dy * radius))
            petal.addQuadCurve(to: center,
                control: CGPoint(x: center.x - tangent.dx * radius * 0.7
                    + direction.dx * radius,
                                 y: center.y - tangent.dy * radius * 0.7
                    + direction.dy * radius))
            ctx.fill(petal, with: .color(petalColor.opacity(0.78)))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - radius * 0.42,
                   y: center.y - radius * 0.42, width: radius * 0.84,
                   height: radius * 0.84)), with: .color(centerColor))
    }

    static func rosette(_ ctx: GraphicsContext, center: CGPoint,
                        radius: CGFloat, fill: Color, stroke: Color,
                        accent: Color) {
        var polygon = Path()
        for step in 0..<16 {
            let angle = Double(step) * Double.pi / 8.0 - Double.pi / 2
            let length = radius * (step.isMultiple(of: 2) ? 1.0 : 0.57)
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * length,
                                y: center.y + CGFloat(sin(angle)) * length)
            if step == 0 { polygon.move(to: point) }
            else { polygon.addLine(to: point) }
        }
        polygon.closeSubpath()
        ctx.fill(polygon, with: .color(fill))
        ctx.stroke(polygon, with: .color(stroke), lineWidth: 1.0)
        flower(ctx, center: center, radius: radius * 0.18, petals: 8,
               petalColor: accent, centerColor: stroke)
    }

    static func vine(_ ctx: GraphicsContext, x: CGFloat,
                     top: CGFloat, bottom: CGFloat,
                     side: CGFloat, template: ManuscriptTemplate) {
        guard bottom > top else { return }
        var stem = Path()
        stem.move(to: CGPoint(x: x, y: top))
        let segment: CGFloat = 77
        var y = top
        while y + segment <= bottom {
            let next = min(bottom, y + segment)
            stem.addCurve(to: CGPoint(x: x, y: next),
                control1: CGPoint(x: x + side * 9, y: y + segment * 0.28),
                control2: CGPoint(x: x - side * 9, y: y + segment * 0.74))
            y = next
        }
        if y < bottom { stem.addLine(to: CGPoint(x: x, y: bottom)) }
        ctx.stroke(stem, with: .color(template.metal.opacity(0.88)),
                   style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

        for (index, value) in stride(from: top + 32, to: bottom - 12,
                                     by: segment).enumerated() {
            let direction: CGFloat = index.isMultiple(of: 2) ? side : -side
            let c = CGPoint(x: x + direction * 1.7, y: value)
            var leaf = Path()
            leaf.move(to: c)
            leaf.addQuadCurve(to: CGPoint(x: c.x + direction * 12,
                                          y: c.y - 16),
                control: CGPoint(x: c.x + direction * 21, y: c.y - 12))
            leaf.addQuadCurve(to: c,
                control: CGPoint(x: c.x + direction * 3, y: c.y - 16))
            ctx.fill(leaf, with: .color(template.leaf.opacity(0.94)))
            flower(ctx, center: CGPoint(x: x + direction * 2, y: value + 19),
                   radius: 3.4, petals: 7, petalColor: template.blossom,
                   centerColor: template.metal)
        }
    }
}
#endif
