#!/usr/bin/env swift
// Original Arash vector identity rendered as a 1024px PNG for iconutil.
// No image-generation service, borrowed illustration or external font needed.
import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: swift scripts/create-app-icon.swift /path/to/icon.png")
}
let output = URL(fileURLWithPath: CommandLine.arguments[1])

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: 1024,
    pixelsHigh: 1024,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0),
    let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Cannot create app icon bitmap.")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

NSColor(calibratedRed: 0.071, green: 0.208, blue: 0.298, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 1024, height: 1024),
             xRadius: 204, yRadius: 204).fill()

let border = NSBezierPath(ovalIn: NSRect(x: 110, y: 110, width: 804, height: 804))
border.lineWidth = 4
NSColor(calibratedRed: 0.78, green: 0.64, blue: 0.42, alpha: 0.34).setStroke()
border.stroke()

let gold = NSColor(calibratedRed: 0.91, green: 0.79, blue: 0.56, alpha: 1)
let ivory = NSColor(calibratedRed: 0.976, green: 0.92, blue: 0.82, alpha: 1)

let bow = NSBezierPath()
bow.move(to: NSPoint(x: 384, y: 812))
bow.curve(to: NSPoint(x: 384, y: 212),
          controlPoint1: NSPoint(x: 146, y: 660),
          controlPoint2: NSPoint(x: 146, y: 360))
bow.lineWidth = 32
bow.lineCapStyle = .round
gold.setStroke()
bow.stroke()

let string = NSBezierPath()
string.move(to: NSPoint(x: 384, y: 812))
string.line(to: NSPoint(x: 478, y: 512))
string.line(to: NSPoint(x: 384, y: 212))
string.lineWidth = 10
string.lineCapStyle = .round
string.stroke()

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 270, y: 512))
arrow.line(to: NSPoint(x: 753, y: 512))
arrow.lineWidth = 26
arrow.lineCapStyle = .round
ivory.setStroke()
arrow.stroke()

let tip = NSBezierPath()
tip.move(to: NSPoint(x: 675, y: 584))
tip.line(to: NSPoint(x: 816, y: 512))
tip.line(to: NSPoint(x: 675, y: 440))
tip.close()
gold.setFill()
tip.fill()

let feathers = NSBezierPath()
feathers.move(to: NSPoint(x: 270, y: 512))
feathers.line(to: NSPoint(x: 332, y: 574))
feathers.move(to: NSPoint(x: 270, y: 512))
feathers.line(to: NSPoint(x: 332, y: 450))
feathers.lineWidth = 13
feathers.lineCapStyle = .round
ivory.setStroke()
feathers.stroke()

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Cannot encode app icon.")
}
try png.write(to: output, options: .atomic)
print("Created original Arash icon at \(output.path)")
