import AppKit
import ServiceManagement

final class StatusBar: NSObject {
	private var statusItem: NSStatusItem?
	private let layouts: [Layout]
	private let spacing: Spacing
	private let hideOthers: Bool
	private var availableUpdate: Updater.Release?

	init(layouts: [Layout], spacing: Spacing, hideOthers: Bool) {
		self.layouts = layouts
		self.spacing = spacing
		self.hideOthers = hideOthers
	}

	func setup() {
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

		if let button = statusItem?.button {
			button.image = makeMenuBarIcon()
		}

		rebuildMenu()
		checkForUpdate()
	}

	private func checkForUpdate() {
		Updater.checkForUpdate { [weak self] release in
			guard let release = release else { return }
			DispatchQueue.main.async {
				self?.availableUpdate = release
				self?.rebuildMenu()
				print("[tiler] Update available: v\(release.version)")
			}
		}
	}

	private func rebuildMenu() {
		let menu = NSMenu()

		// Layouts
		for (index, layout) in layouts.enumerated() {
			let item = NSMenuItem(title: "\(layout.name) (\(layout.hotkey))", action: #selector(applyLayoutAction(_:)), keyEquivalent: "")
			item.target = self
			item.tag = index
			menu.addItem(item)
		}

		menu.addItem(.separator())

		// Permissions status
		let accessibilityGranted = WindowManager.checkAccessibility(prompt: false)
		let permItem = NSMenuItem(title: "Accessibility: \(accessibilityGranted ? "Granted" : "Not Granted")", action: accessibilityGranted ? nil : #selector(openAccessibility), keyEquivalent: "")
		permItem.target = self
		if !accessibilityGranted {
			permItem.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Warning")
		} else {
			permItem.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "OK")
		}
		menu.addItem(permItem)

		// Launch at login
		let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
		launchItem.target = self
		launchItem.state = isLaunchAtLoginEnabled() ? .on : .off
		menu.addItem(launchItem)

		// Edit config
		let editItem = NSMenuItem(title: "Edit Config...", action: #selector(openConfig), keyEquivalent: ",")
		editItem.target = self
		menu.addItem(editItem)

		// Update available
		if let update = availableUpdate {
			let updateItem = NSMenuItem(title: "Update Available (v\(update.version))", action: #selector(openUpdate), keyEquivalent: "")
			updateItem.target = self
			updateItem.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "Update")
			menu.addItem(updateItem)
		}

		// Version
		let versionItem = NSMenuItem(title: "v\(Updater.currentVersion)", action: nil, keyEquivalent: "")
		versionItem.isEnabled = false
		menu.addItem(versionItem)

		menu.addItem(.separator())

		let quitItem = NSMenuItem(title: "Quit Tiler", action: #selector(quit), keyEquivalent: "q")
		quitItem.target = self
		menu.addItem(quitItem)

		statusItem?.menu = menu
	}

	// MARK: - Menu Bar Icon

	private func makeMenuBarIcon() -> NSImage {
		let size = NSSize(width: 17, height: 17)
		let image = NSImage(size: size, flipped: false) { rect in
			let r: CGFloat = 1.3
			let lw: CGFloat = 1.0
			let p: CGFloat = 2 // padding

			let w = size.width - p * 2
			let h = size.height - p * 2

			let rects = [
				NSRect(x: p, y: p, width: w * 0.38, height: h),                    // Left tall column
				NSRect(x: p + w * 0.42, y: p + h * 0.52, width: w * 0.27, height: h * 0.48),  // Top-middle
				NSRect(x: p + w * 0.73, y: p + h * 0.52, width: w * 0.27, height: h * 0.48),  // Top-right
				NSRect(x: p + w * 0.42, y: p, width: w * 0.58, height: h * 0.48),  // Bottom-right wide
			]

			for r2 in rects {
				let path = NSBezierPath(roundedRect: r2.insetBy(dx: lw / 2, dy: lw / 2), xRadius: r, yRadius: r)
				path.lineWidth = lw
				path.stroke()
			}

			return true
		}
		image.isTemplate = true
		return image
	}

	// MARK: - Actions

	@objc private func applyLayoutAction(_ sender: NSMenuItem) {
		let index = sender.tag
		guard index >= 0, index < layouts.count else { return }
		WindowManager.applyLayout(layouts[index], spacing: spacing, hideOthers: hideOthers)
	}

	@objc private func openAccessibility() {
		let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
		NSWorkspace.shared.open(url)
	}

	@objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
		let newState = !isLaunchAtLoginEnabled()
		setLaunchAtLogin(newState)
		sender.state = newState ? .on : .off
	}

	@objc private func openUpdate() {
		if Updater.isHomebrew {
			Updater.brewUpgrade()
		} else {
			guard let update = availableUpdate, let url = URL(string: update.url) else { return }
			NSWorkspace.shared.open(url)
		}
	}

	@objc private func openConfig() {
		let path = (Config.defaultPath as NSString).expandingTildeInPath
		let url = URL(fileURLWithPath: path)
		let fm = FileManager.default

		// Create directory if needed
		let dir = url.deletingLastPathComponent().path
		if !fm.fileExists(atPath: dir) {
			try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
		}

		// Create default config if file doesn't exist
		if !fm.fileExists(atPath: path) {
			let defaultConfig = """
			# Tiler config
			# x, y, width, height are percentages of the usable screen area
			# spacing: "1%" (percentage) or "10px" (pixels)
			# hide_others: hide apps not in the active layout

			spacing = "1%"
			hide_others = true

			[[layout]]
			name = "main"
			hotkey = "alt+1"

			  [[layout.window]]
			  app = "Terminal"
			  x = 0
			  y = 0
			  width = 50
			  height = 100

			  [[layout.window]]
			  app = "Safari"
			  x = 50
			  y = 0
			  width = 50
			  height = 100
			"""
			fm.createFile(atPath: path, contents: defaultConfig.data(using: .utf8))
		}

		NSWorkspace.shared.open(url)
	}

	@objc private func quit() {
		NSApplication.shared.terminate(nil)
	}

	// MARK: - Launch at Login

	private func isLaunchAtLoginEnabled() -> Bool {
		SMAppService.mainApp.status == .enabled
	}

	private func setLaunchAtLogin(_ enabled: Bool) {
		do {
			if enabled {
				try SMAppService.mainApp.register()
			} else {
				try SMAppService.mainApp.unregister()
			}
		} catch {
			print("[tiler] Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
		}
	}
}
