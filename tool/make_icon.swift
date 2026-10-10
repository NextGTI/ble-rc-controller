// Draws the app icon (red toy car with a game controller in front) as a
// 1024x1024 PNG. Run: swift tool/make_icon.swift assets/icon/icon.png
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// Work in a top-left origin.
ctx.translateBy(x: 0, y: CGFloat(size)); ctx.scaleBy(x: 1, y: -1)

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [CGFloat((hex >> 16) & 255) / 255, CGFloat((hex >> 8) & 255) / 255,
                                         CGFloat(hex & 255) / 255, a])!
}
func rr(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: r, cornerHeight: r, transform: nil)
}
func fill(_ p: CGPath, _ c: CGColor) { ctx.addPath(p); ctx.setFillColor(c); ctx.fillPath() }
func stroke(_ p: CGPath, _ c: CGColor, _ w: CGFloat) {
    ctx.addPath(p); ctx.setStrokeColor(c); ctx.setLineWidth(w); ctx.setLineJoin(.round); ctx.strokePath()
}
func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r), transform: nil)
}

// --- Background: rounded square, light gradient -----------------------------
let bg = rr(100, 100, 824, 824, 190)
ctx.saveGState()
ctx.addPath(bg); ctx.clip()
let grad = CGGradient(colorsSpace: cs, colors: [rgb(0xFFFFFF), rgb(0xE3E6EB)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: [])
ctx.restoreGState()
stroke(bg, rgb(0x000000, 0.08), 3)

ctx.saveGState()
ctx.addPath(bg); ctx.clip()

// --- Car (side view) ---------------------------------------------------------
let dy: CGFloat = -10
ctx.saveGState(); ctx.translateBy(x: 0, y: dy)

// shadow
fill(CGPath(ellipseIn: CGRect(x: 230, y: 668, width: 580, height: 44), transform: nil), rgb(0x000000, 0.10))

// cabin
let cabin = CGMutablePath()
cabin.move(to: CGPoint(x: 330, y: 470))
cabin.addCurve(to: CGPoint(x: 420, y: 372), control1: CGPoint(x: 340, y: 420), control2: CGPoint(x: 375, y: 372))
cabin.addLine(to: CGPoint(x: 625, y: 372))
cabin.addCurve(to: CGPoint(x: 735, y: 470), control1: CGPoint(x: 690, y: 372), control2: CGPoint(x: 715, y: 430))
cabin.closeSubpath()
fill(cabin, rgb(0xD32F2F))

// body
fill(rr(190, 450, 650, 175, 78), rgb(0xE53935))
// highlight stripe
fill(rr(240, 470, 540, 26, 13), rgb(0xFFFFFF, 0.22))

// windows
let w1 = CGMutablePath()
w1.move(to: CGPoint(x: 372, y: 450)); w1.addLine(to: CGPoint(x: 432, y: 396))
w1.addLine(to: CGPoint(x: 510, y: 396)); w1.addLine(to: CGPoint(x: 510, y: 450)); w1.closeSubpath()
fill(w1, rgb(0xD6ECFF))
let w2 = CGMutablePath()
w2.move(to: CGPoint(x: 536, y: 396)); w2.addLine(to: CGPoint(x: 620, y: 396))
w2.addCurve(to: CGPoint(x: 690, y: 450), control1: CGPoint(x: 655, y: 396), control2: CGPoint(x: 675, y: 425))
w2.addLine(to: CGPoint(x: 536, y: 450)); w2.closeSubpath()
fill(w2, rgb(0xD6ECFF))

// lights
fill(rr(792, 500, 42, 34, 14), rgb(0xFFE082))
fill(rr(196, 500, 30, 34, 12), rgb(0xFFAB91))

// wheels
for cx in [CGFloat(330), CGFloat(700)] {
    fill(circle(cx, 622, 70), rgb(0x263238))
    fill(circle(cx, 622, 34), rgb(0xCFD8DC))
    fill(circle(cx, 622, 12), rgb(0x78909C))
}
ctx.restoreGState()

// --- Controller in front -----------------------------------------------------
let cx: CGFloat = 512, cy: CGFloat = 722
ctx.saveGState()
ctx.translateBy(x: cx, y: cy); ctx.scaleBy(x: 0.80, y: 0.80); ctx.translateBy(x: -cx, y: -cy)
let pad = CGMutablePath()
pad.addPath(rr(cx - 235, cy - 80, 470, 160, 80))                       // centre
pad.addPath(CGPath(ellipseIn: CGRect(x: cx - 275, y: cy - 20, width: 190, height: 230), transform: nil)) // left grip
pad.addPath(CGPath(ellipseIn: CGRect(x: cx + 85, y: cy - 20, width: 190, height: 230), transform: nil))  // right grip
// white outline so it separates from the car
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 10), blur: 22, color: rgb(0x000000, 0.35))
fill(pad, rgb(0xFFFFFF))
ctx.restoreGState()
// inset body
ctx.saveGState()
ctx.translateBy(x: cx, y: cy); ctx.scaleBy(x: 0.955, y: 0.93); ctx.translateBy(x: -cx, y: -cy - 4)
fill(pad, rgb(0xB71C1C))
ctx.restoreGState()

// d-pad
let dx: CGFloat = cx - 125, dyy: CGFloat = cy - 14
fill(rr(dx - 17, dyy - 52, 34, 104, 9), rgb(0xFFFFFF))
fill(rr(dx - 52, dyy - 17, 104, 34, 9), rgb(0xFFFFFF))
// face buttons
let bx: CGFloat = cx + 125, by: CGFloat = cy - 14
for (ox, oy, col) in [(0, -42, 0xFFFFFF), (0, 42, 0xFFFFFF), (-42, 0, 0xFFFFFF), (42, 0, 0xFFFFFF)] as [(CGFloat, CGFloat, UInt32)] {
    fill(circle(bx + ox, by + oy, 20), rgb(col))
}
// sticks
for sx in [cx - 55, cx + 55] {
    fill(circle(sx, cy + 62, 34), rgb(0x7F1212))
    fill(circle(sx, cy + 62, 22), rgb(0xE57373))
}
// centre buttons
fill(rr(cx - 28, cy - 38, 22, 12, 6), rgb(0xFFFFFF, 0.9))
fill(rr(cx + 6, cy - 38, 22, 12, 6), rgb(0xFFFFFF, 0.9))

ctx.restoreGState()   // controller scale
ctx.restoreGState()   // clip to the rounded square

// --- Write PNG -----------------------------------------------------------------
let img = ctx.makeImage()!
let url = URL(fileURLWithPath: out) as CFURL
let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
precondition(CGImageDestinationFinalize(dest))
print("wrote \(out)")
