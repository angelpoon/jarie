import AppKit
import SwiftUI

/// Manages toast panel lifecycle: show, auto-dismiss, and rapid-capture replacement.
@MainActor
final class ToastCoordinator {
    private var panel: ToastPanel?
    private var dismissWorkItem: DispatchWorkItem?

    func show(content: String, sourceURL: String?, title: String?) {
        // Cancel pending dismiss
        dismissWorkItem?.cancel()

        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        // Create or reuse panel
        let toastView = ToastView(content: content, sourceURL: sourceURL, title: title)
        let hostingView = NSHostingView(rootView: toastView)
        hostingView.frame.size = hostingView.fittingSize

        if panel == nil {
            panel = ToastPanel(
                contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
        }

        guard let panel else { return }
        panel.contentView = hostingView
        panel.setContentSize(hostingView.fittingSize)

        // Position: upper-right of the screen containing the frontmost app
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = hostingView.fittingSize
        let origin = NSPoint(
            x: screenFrame.maxX - panelSize.width - 16,
            y: screenFrame.maxY - panelSize.height - 8
        )
        panel.setFrameOrigin(origin)

        // Show with animation
        if reduceMotion {
            panel.alphaValue = 1
            panel.orderFrontRegardless()
        } else {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        }

        // Schedule auto-dismiss after 1.8 seconds
        let workItem = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.dismiss() }
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: workItem)
    }

    private func dismiss() {
        guard let panel, panel.isVisible else { return }
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        if reduceMotion {
            panel.orderOut(nil)
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                panel.animator().alphaValue = 0
            }, completionHandler: {
                MainActor.assumeIsolated { [weak self] in
                    self?.panel?.orderOut(nil)
                }
            })
        }
    }
}
