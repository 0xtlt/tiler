import AppKit

struct Screen {
	/// Usable screen area (excludes menu bar and dock)
	static var visibleFrame: CGRect {
		NSScreen.main?.visibleFrame ?? .zero
	}

	/// Full screen frame including menu bar
	static var fullFrame: CGRect {
		NSScreen.main?.frame ?? .zero
	}

	/// Convert spacing to pixels
	static func spacingPixels(_ spacing: Spacing) -> Double {
		if spacing.isPercent {
			let minDim = min(visibleFrame.width, visibleFrame.height)
			return minDim * spacing.value / 100.0
		} else {
			return spacing.value
		}
	}

	/// Convert percentage-based rect to pixel coordinates (AX top-left origin) with spacing
	static func percentToPixels(
		x: Double, y: Double, width: Double, height: Double,
		spacing: Spacing = .default
	) -> (CGPoint, CGSize) {
		let visible = visibleFrame
		let full = fullFrame
		let gap = spacingPixels(spacing)

		let menuBarHeight = full.height - visible.maxY

		// Raw position and size from percentages
		let rawX = visible.origin.x + (visible.width * x / 100.0)
		let rawY = menuBarHeight + (visible.height * y / 100.0)
		let rawW = visible.width * width / 100.0
		let rawH = visible.height * height / 100.0

		// Apply spacing: outer gap on edges, half gap between windows
		let isLeftEdge = x < 1
		let isTopEdge = y < 1
		let isRightEdge = (x + width) > 99
		let isBottomEdge = (y + height) > 99

		let leftGap = isLeftEdge ? gap : gap / 2
		let topGap = isTopEdge ? gap : gap / 2
		let rightGap = isRightEdge ? gap : gap / 2
		let bottomGap = isBottomEdge ? gap : gap / 2

		let finalX = rawX + leftGap
		let finalY = rawY + topGap
		let finalW = rawW - leftGap - rightGap
		let finalH = rawH - topGap - bottomGap

		return (CGPoint(x: finalX, y: finalY), CGSize(width: finalW, height: finalH))
	}
}
