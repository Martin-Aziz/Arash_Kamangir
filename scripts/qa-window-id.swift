#!/usr/bin/env swift
// Returns the CGWindow ID of the isolated QA app, not whichever desktop
// window happens to be frontmost. Used by qa-capture-window.sh on macOS.
import AppKit
import CoreGraphics
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("QA capture: " + message + "\n").utf8))
    exit(1)
}

let bundleID = "com.arashkam.reader.qa"
let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
guard !apps.isEmpty else {
    fail("ArashKam-QA.app is not running. Open dist/ArashKam-QA.app first.")
}
let pids = Set(apps.map(\.processIdentifier))

guard let windows = CGWindowListCopyWindowInfo(
    [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
) as? [[String: Any]] else {
    fail("Cannot inspect desktop windows; check Screen Recording permissions.")
}

for window in windows {
    guard let pid = window[kCGWindowOwnerPID as String] as? NSNumber,
          pids.contains(pid.int32Value),
          let layer = window[kCGWindowLayer as String] as? NSNumber,
          layer.intValue == 0,
          let bounds = window[kCGWindowBounds as String] as? [String: Any],
          let width = bounds["Width"] as? NSNumber,
          let height = bounds["Height"] as? NSNumber,
          width.doubleValue >= 450,
          height.doubleValue >= 300,
          let number = window[kCGWindowNumber as String] as? NSNumber else {
        continue
    }
    print(number.intValue)
    exit(0)
}
fail("No visible QA app window found. Bring ArashKam-QA to the front and retry.")
