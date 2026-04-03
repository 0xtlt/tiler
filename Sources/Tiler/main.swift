import AppKit
import Foundation

// ─── Config path ─────────────────────────────────────────────

let configPath: String
if CommandLine.arguments.count > 1 {
	configPath = CommandLine.arguments[1]
} else {
	configPath = Config.defaultPath
}

// ─── Check Accessibility ─────────────────────────────────────

if !WindowManager.checkAccessibility() {
	print("[tiler] Accessibility permission required.")
	print("[tiler] Go to System Settings > Privacy & Security > Accessibility")
	print("[tiler] Add this terminal app or the tiler binary, then restart.")
	exit(1)
}

// ─── Start ───────────────────────────────────────────────────

do {
	let controller = try AppController(configPath: configPath)
	controller.start()
} catch {
	print("[tiler] Failed to load config from \(configPath): \(error)")
	exit(1)
}
