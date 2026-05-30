// Renamed: contains PendulumView (arc/dial/bars swing visualizations)
import SwiftUI

// MARK: - Swing pose math (ported from Pendulum.jsx)

private struct SwingPose { var shoulder: Double; var club: Double }

private func easeOutSine(_ t: Double) -> Double { sin(t * .pi / 2) }
private func easeInSine(_ t: Double)  -> Double { 1 - cos(t * .pi / 2) }
private func easeInQuad(_ t: Double)  -> Double { t * t }

private func getSwingPose(_ frame: TempoFrame) -> SwingPose {
    let aS = 25.0, aC = 25.0
    switch frame.phase {
    case .idle:
        return SwingPose(shoulder: aS, club: aC)
    case .back:
        let e = easeOutSine(frame.phaseT)
        return SwingPose(shoulder: aS + e * -110, club: aC + e * -205)
    case .down:
        let e = easeInSine(frame.phaseT)
        let shoulder = -85.0 + e * 110
        let club: Double = frame.phaseT < 0.55
            ? -180 + (frame.phaseT / 0.55) * 90
            : -90 + easeInQuad((frame.phaseT - 0.55) / 0.45) * 115
        return SwingPose(shoulder: shoulder, club: club)
    case .rest:
        if frame.phaseT < 0.30 {
            let e = easeOutSine(frame.phaseT / 0.30)
            return SwingPose(shoulder: aS + e * 95, club: aC + e * 175)
        } else {
            let e = easeOutSine((frame.phaseT - 0.30) / 0.70)
            return SwingPose(shoulder: 120 - e * 95, club: 200 - e * 175)
        }
    }
}

private func deg2pt(_ o: CGPoint, _ len: CGFloat, _ deg: Double) -> CGPoint {
    let r = deg * .pi / 180
    return CGPoint(x: o.x + len * sin(r), y: o.y + len * cos(r))
}

// MARK: - Arc visualization

struct PendulumArcView: View {
    let frame: TempoFrame
    let ratio: Double
    let swingMs: Double
    @Environment(\.tc) var colors

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let groundY   = h * 0.84
            let shoulder  = CGPoint(x: w * 0.50, y: h * 0.34)
            let armLen    = h * 0.20
            let clubLen   = h * 0.27

            let pose  = getSwingPose(frame)
            let wrist = deg2pt(shoulder, armLen,  pose.shoulder)
            let head  = deg2pt(wrist,   clubLen,  pose.club)

            // Precomputed swing trail
            var trail = Path()
            for i in 0...44 {
                let u = Double(i) / 44
                let f = u < 0.5
                    ? TempoFrame(phase: .back, phaseT: u * 2, cycleT: u, swingCount: 0)
                    : TempoFrame(phase: .down, phaseT: (u - 0.5) * 2, cycleT: u, swingCount: 0)
                let p  = getSwingPose(f)
                let tw = deg2pt(shoulder, armLen, p.shoulder)
                let th = deg2pt(tw, clubLen, p.club)
                i == 0 ? trail.move(to: th) : trail.addLine(to: th)
            }

            // Ground
            var gl = Path(); gl.move(to: CGPoint(x: 14, y: groundY)); gl.addLine(to: CGPoint(x: w - 14, y: groundY))
            ctx.stroke(gl, with: .color(colors.line.opacity(0.5)), lineWidth: 1)

            // Trail
            ctx.stroke(trail, with: .color(colors.inkFaint.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))

            // Ball
            let ballBase = deg2pt(shoulder, armLen + clubLen, 25)
            ctx.fill(Ellipse().path(in: CGRect(x: ballBase.x - 6, y: groundY, width: 12, height: 2.6)), with: .color(.black.opacity(0.18)))
            ctx.fill(Circle().path(in: CGRect(x: ballBase.x - 3.8, y: groundY - 7.6, width: 7.6, height: 7.6)), with: .color(colors.ink))

            // Silhouette
            let hips = CGPoint(x: shoulder.x + 6, y: groundY - 56)
            let silOpacity = 0.45
            func silhouette(_ path: Path) { ctx.stroke(path, with: .color(colors.inkSoft.opacity(silOpacity)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round)) }
            silhouette(Circle().path(in: CGRect(x: shoulder.x - 13, y: shoulder.y - 34, width: 16, height: 16)))
            var sp = Path(); sp.move(to: CGPoint(x: shoulder.x - 3, y: shoulder.y - 18)); sp.addLine(to: CGPoint(x: shoulder.x, y: shoulder.y - 3)); silhouette(sp)
            var torso = Path(); torso.move(to: CGPoint(x: shoulder.x, y: shoulder.y - 2)); torso.addCurve(to: hips, control1: CGPoint(x: shoulder.x + 3, y: (shoulder.y + hips.y) / 2), control2: hips); silhouette(torso)
            var hipsLine = Path(); hipsLine.move(to: CGPoint(x: hips.x - 5, y: hips.y)); hipsLine.addLine(to: CGPoint(x: hips.x + 6, y: hips.y)); silhouette(hipsLine)
            var bl = Path(); bl.move(to: CGPoint(x: hips.x - 3, y: hips.y)); bl.addLine(to: CGPoint(x: hips.x - 14, y: groundY - 1)); silhouette(bl)
            var fl = Path(); fl.move(to: CGPoint(x: hips.x + 4, y: hips.y)); fl.addQuadCurve(to: CGPoint(x: hips.x + 18, y: groundY - 1), control: CGPoint(x: hips.x + 14, y: (hips.y + groundY) / 2)); silhouette(fl)

            // Arms
            ctx.fill(Circle().path(in: CGRect(x: shoulder.x - 2.8, y: shoulder.y - 2.8, width: 5.6, height: 5.6)), with: .color(colors.ink))
            var arms = Path(); arms.move(to: shoulder); arms.addLine(to: wrist)
            ctx.stroke(arms, with: .color(colors.ink), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
            ctx.fill(Circle().path(in: CGRect(x: wrist.x - 2.4, y: wrist.y - 2.4, width: 4.8, height: 4.8)), with: .color(colors.ink))
            var clubPath = Path(); clubPath.move(to: wrist); clubPath.addLine(to: head)
            ctx.stroke(clubPath, with: .color(colors.inkSoft), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

            // Beat flash
            let fw = 0.08
            let beatGlow: Double = {
                switch frame.phase {
                case .back where frame.phaseT < fw: return 1 - frame.phaseT / fw
                case .down where frame.phaseT < fw: return 1 - frame.phaseT / fw
                case .rest where frame.phaseT < fw: return 1 - frame.phaseT / fw
                default: return 0
                }
            }()
            if beatGlow > 0 {
                let beatColor = frame.phase == .rest ? colors.gold : colors.accent
                let rr = CGFloat(8 + (1 - beatGlow) * 26)
                ctx.stroke(Circle().path(in: CGRect(x: head.x - rr, y: head.y - rr, width: rr * 2, height: rr * 2)), with: .color(beatColor.opacity(beatGlow * 0.75)), lineWidth: 2)
                ctx.fill(Circle().path(in: CGRect(x: head.x - 7, y: head.y - 7, width: 14, height: 14)), with: .color(beatColor.opacity(beatGlow * 0.35)))
            }
        }
    }
}

// MARK: - Dial visualization

struct PendulumDialView: View {
    let frame: TempoFrame
    let ratio: Double
    let swingMs: Double
    @Environment(\.tc) var colors

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2, cy = size.height / 2
            let r = size.width * 0.36
            let back = swingMs * ratio / (ratio + 1)
            let down = swingMs / (ratio + 1)
            let cycleApprox = swingMs + 2200
            let backDeg = (back / cycleApprox) * 360
            let downDeg = (down / cycleApprox) * 360
            let center = CGPoint(x: cx, y: cy)

            ctx.stroke(Circle().path(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                       with: .color(colors.line.opacity(0.6)), lineWidth: 1.5)
            ctx.stroke(Path { p in p.addArc(center: center, radius: r, startAngle: .degrees(-90), endAngle: .degrees(-90 + backDeg), clockwise: false) },
                       with: .color(colors.accent.opacity(0.4)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            ctx.stroke(Path { p in p.addArc(center: center, radius: r, startAngle: .degrees(-90 + backDeg), endAngle: .degrees(-90 + backDeg + downDeg), clockwise: false) },
                       with: .color(colors.gold.opacity(0.55)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            var tick = Path(); tick.move(to: CGPoint(x: cx, y: cy - r - 8)); tick.addLine(to: CGPoint(x: cx, y: cy - r + 8))
            ctx.stroke(tick, with: .color(colors.ink), lineWidth: 1.5)
            let pAngle = (frame.cycleT * 360 - 90) * .pi / 180
            let tip = CGPoint(x: cx + cos(pAngle) * r * 0.92, y: cy + sin(pAngle) * r * 0.92)
            var ptr = Path(); ptr.move(to: center); ptr.addLine(to: tip)
            ctx.stroke(ptr, with: .color(colors.ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            ctx.fill(Circle().path(in: CGRect(x: tip.x - 6, y: tip.y - 6, width: 12, height: 12)), with: .color(colors.ink))
            ctx.fill(Circle().path(in: CGRect(x: cx - 4, y: cy - 4, width: 8, height: 8)), with: .color(colors.ink))
        }
        .overlay {
            Text(frame.phase == .idle ? "READY" : frame.phase.rawValue.uppercased())
                .font(.system(size: 10, weight: .medium)).tracking(2)
                .foregroundColor(colors.inkFaint)
                .offset(y: 32)
        }
    }
}

// MARK: - Bars visualization

struct PendulumBarsView: View {
    let frame: TempoFrame
    let ratio: Double
    let swingMs: Double
    @Environment(\.tc) var colors

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let back = swingMs * ratio / (ratio + 1)
            let down = swingMs / (ratio + 1)
            let total = back + down
            let padX = w * 0.09
            let innerW = w - padX * 2
            let backW = innerW * CGFloat(back / total)
            let downW = innerW * CGFloat(down / total)
            let barH: CGFloat = 34
            let topY: CGFloat = 48
            let bottomY = topY + barH + 26
            let backFrames = Int((back / 1000 * 30).rounded())
            let downFrames = Int((down / 1000 * 30).rounded())
            let backFill = CGFloat(frame.phase == .back ? frame.phaseT : (frame.phase == .idle ? 0 : 1))
            let downFill = CGFloat(frame.phase == .down ? frame.phaseT : (frame.phase == .idle || frame.phase == .back ? 0 : 1))

            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    // Back bar
                    ctx.fill(RoundedRectangle(cornerRadius: 6).path(in: CGRect(x: padX, y: topY, width: backW, height: barH)), with: .color(colors.surface2))
                    if backFill > 0 {
                        ctx.fill(RoundedRectangle(cornerRadius: 6).path(in: CGRect(x: padX, y: topY, width: backW * backFill, height: barH)), with: .color(colors.accent.opacity(0.7)))
                    }
                    // Down bar
                    ctx.fill(RoundedRectangle(cornerRadius: 6).path(in: CGRect(x: padX, y: bottomY, width: downW, height: barH)), with: .color(colors.surface2))
                    if downFill > 0 {
                        ctx.fill(RoundedRectangle(cornerRadius: 6).path(in: CGRect(x: padX, y: bottomY, width: downW * downFill, height: barH)), with: .color(colors.gold.opacity(0.85)))
                    }
                }
                // Labels
                VStack(spacing: 0) {
                    HStack {
                        Text("BACKSWING").font(.system(size: 9.5, weight: .medium)).tracking(2).foregroundColor(colors.inkFaint)
                        Spacer()
                        Text("\(backFrames)f").font(.system(size: 10, weight: .medium).monospacedDigit()).foregroundColor(colors.inkSoft)
                    }.padding(.horizontal, padX)
                    Spacer().frame(height: barH + 14)
                    HStack {
                        Text("DOWNSWING").font(.system(size: 9.5, weight: .medium)).tracking(2).foregroundColor(colors.inkFaint)
                        Spacer()
                        Text("\(downFrames)f").font(.system(size: 10, weight: .medium).monospacedDigit()).foregroundColor(colors.inkSoft)
                    }.padding(.horizontal, padX)
                }
                .padding(.top, topY - 14)

                // Ratio
                Text(String(format: "%.1f:1", ratio))
                    .font(.system(size: 22, weight: .medium).monospacedDigit())
                    .foregroundColor(colors.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, topY + barH + 10)
            }
            .frame(width: w)
        }
    }
}

// MARK: - Unified Pendulum

struct PendulumView: View {
    let style: AppStore.VizStyle
    let frame: TempoFrame
    let ratio: Double
    let swingMs: Double

    var body: some View {
        switch style {
        case .arc:  PendulumArcView(frame: frame, ratio: ratio, swingMs: swingMs)
        case .dial: PendulumDialView(frame: frame, ratio: ratio, swingMs: swingMs)
        case .bars: PendulumBarsView(frame: frame, ratio: ratio, swingMs: swingMs)
        }
    }
}
