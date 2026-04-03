import AppKit
import Foundation

// ─── Single instance ────────────────────────────────────────

let lockPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("vitrail.lock")
let lockFD = open(lockPath, O_CREAT | O_RDWR, 0o644)
if lockFD != -1 && flock(lockFD, LOCK_EX | LOCK_NB) == -1 {
	// Lock held by another instance – tell it to open the configurator, then exit
	DistributedNotificationCenter.default().postNotificationName(
		NSNotification.Name("com.thomastastet.vitrail.openConfigurator"),
		object: nil,
		userInfo: nil,
		deliverImmediately: true
	)
	print("[vitrail] Already running – opening configurator in existing instance.")
	exit(0)
}

// ─── Config path ─────────────────────────────────────────────

let configPath: String
if CommandLine.arguments.count > 1 {
	configPath = CommandLine.arguments[1]
} else {
	configPath = Config.defaultPath
}

// ─── Check Accessibility ─────────────────────────────────────

if !WindowManager.checkAccessibility() {
	print("[vitrail] Accessibility permission required.")
	print("[vitrail] Go to System Settings > Privacy & Security > Accessibility")
	print("[vitrail] Add this terminal app or the vitrail binary, then restart.")
	exit(1)
}

// ─── Start ───────────────────────────────────────────────────

do {
	let controller = try AppController(configPath: configPath)
	controller.start()
} catch {
	print("[vitrail] Failed to load config from \(configPath): \(error)")
	exit(1)
}
