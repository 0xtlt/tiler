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

// ─── Load config ─────────────────────────────────────────────

let config: Config
do {
	config = try Config.load(from: configPath)
} catch {
	print("[tiler] Failed to load config from \(configPath): \(error)")
	exit(1)
}

if config.layouts.isEmpty {
	print("[tiler] No layouts found in config.")
	exit(1)
}

print("[tiler] Loaded \(config.layouts.count) layout(s)")

// ─── Register hotkeys ────────────────────────────────────────

let hotKeyManager = HotKeyManager()
hotKeyManager.register(layouts: config.layouts, spacing: config.spacing, hideOthers: config.hideOthers)

// ─── Status bar ──────────────────────────────────────────────

let statusBar = StatusBar(layouts: config.layouts, spacing: config.spacing, hideOthers: config.hideOthers)
statusBar.setup()

print("[tiler] Listening for hotkeys... (ctrl+c to quit)")

// ─── Run loop ────────────────────────────────────────────────

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.run()
