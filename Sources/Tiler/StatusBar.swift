import AppKit

final class StatusBar: NSObject {
	private var statusItem: NSStatusItem?
	private let layouts: [Layout]
	private let spacing: Spacing
	private let hideOthers: Bool

	init(layouts: [Layout], spacing: Spacing, hideOthers: Bool) {
		self.layouts = layouts
		self.spacing = spacing
		self.hideOthers = hideOthers
	}

	func setup() {
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

		if let button = statusItem?.button {
			button.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "Tiler")
		}

		let menu = NSMenu()

		for (index, layout) in layouts.enumerated() {
			let item = NSMenuItem(title: "\(layout.name) (\(layout.hotkey))", action: #selector(applyLayoutAction(_:)), keyEquivalent: "")
			item.target = self
			item.tag = index
			menu.addItem(item)
		}

		menu.addItem(.separator())

		let quitItem = NSMenuItem(title: "Quit Tiler", action: #selector(quit), keyEquivalent: "q")
		quitItem.target = self
		menu.addItem(quitItem)

		statusItem?.menu = menu
	}

	@objc private func applyLayoutAction(_ sender: NSMenuItem) {
		let index = sender.tag
		guard index >= 0, index < layouts.count else { return }
		WindowManager.applyLayout(layouts[index], spacing: spacing, hideOthers: hideOthers)
	}

	@objc private func quit() {
		NSApplication.shared.terminate(nil)
	}
}
