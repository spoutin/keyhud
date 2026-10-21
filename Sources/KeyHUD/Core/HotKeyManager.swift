import Foundation
import AppKit
import Carbon

// MARK: - HotKey & Command Listener

class HotKeyManager {
    static let shared = HotKeyManager()
    private var cmdWorkItem: DispatchWorkItem?
    private var consecutiveTapCount: Int = 0
    private var lastCmdUpTime: Date? = nil
    
    private var isCmdCurrentlyDown = false
    private var shouldIgnoreNextCmdUp = false
    private var carbonHotKeyRef: EventHotKeyRef?

    func start() {
        registerCarbonHotKey()

        // Global monitors (when other applications are active)
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // If any key is typed while Command is held (e.g. Cmd+Tab, Cmd+C, Cmd+Space),
            // immediately cancel modifier-hold HUD trigger so app-switching never toggles the HUD
            self?.cancelCmdHold()

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == 44 && flags.contains(.command) && flags.contains(.shift) {
                DispatchQueue.main.async {
                    HUDWindowController.shared.toggle()
                }
            }
        }

        // Local monitors (when KeyHUD is active / overlay is open)
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if EditorState.shared.isRecording { return event }
            self?.cancelCmdHold()

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == 44 && flags.contains(.command) && flags.contains(.shift) {
                DispatchQueue.main.async {
                    HUDWindowController.shared.toggle()
                }
                return nil
            }
            return event
        }
    }

    private func registerCarbonHotKey() {
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.signature = OSType(0x4B485544) // 'KHUD'
        gMyHotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        InstallEventHandler(GetApplicationEventTarget(), { (_, theEvent, _) -> OSStatus in
            if EditorState.shared.isRecording { return noErr }
            DispatchQueue.main.async {
                HUDWindowController.shared.toggle()
            }
            return noErr
        }, 1, &eventType, nil, nil)

        RegisterEventHotKey(
            UInt32(kVK_ANSI_Slash),
            UInt32(cmdKey | shiftKey),
            gMyHotKeyID,
            GetApplicationEventTarget(),
            0,
            &carbonHotKeyRef
        )
    }

    func cancelCmdHold() {
        cmdWorkItem?.cancel()
        cmdWorkItem = nil
        shouldIgnoreNextCmdUp = true
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        if EditorState.shared.isRecording { return }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let isOnlyCmd = flags == .command

        if isOnlyCmd {
            if !isCmdCurrentlyDown {
                isCmdCurrentlyDown = true
                onCmdDown()
            }
        } else {
            if isCmdCurrentlyDown {
                isCmdCurrentlyDown = false
                onCmdUp()
            }
            cmdWorkItem?.cancel()
            cmdWorkItem = nil
        }
    }

    private func onCmdDown() {
        let now = Date()

        // If the gap between the last Up event and this Down event is within 0.5s, it's a consecutive tap.
        if let lastUp = lastCmdUpTime, now.timeIntervalSince(lastUp) < 0.5 {
            consecutiveTapCount += 1
        } else {
            consecutiveTapCount = 1
        }

        let trigger = TriggerType(rawValue: AppSettings.shared.triggerType) ?? .doubleTapAndHold
        let holdSec = AppSettings.shared.holdDuration

        switch trigger {
        case .singleHold:
            let work = DispatchWorkItem { [weak self] in
                self?.shouldIgnoreNextCmdUp = true
                HUDWindowController.shared.toggle()
            }
            cmdWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + holdSec, execute: work)

        case .doubleTap:
            if consecutiveTapCount >= 2 {
                consecutiveTapCount = 0
                shouldIgnoreNextCmdUp = true
                HUDWindowController.shared.toggle()
            }

        case .tripleTap:
            if consecutiveTapCount >= 3 {
                consecutiveTapCount = 0
                shouldIgnoreNextCmdUp = true
                HUDWindowController.shared.toggle()
            }

        case .doubleTapAndHold:
            if consecutiveTapCount >= 2 {
                let holdDelay = max(0.08, holdSec * 0.35)
                let work = DispatchWorkItem { [weak self] in
                    self?.shouldIgnoreNextCmdUp = true
                    HUDWindowController.shared.toggle()
                }
                cmdWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + holdDelay, execute: work)
            }

        case .hotkeyOnly:
            break
        }
    }

    private func onCmdUp() {
        if shouldIgnoreNextCmdUp {
            shouldIgnoreNextCmdUp = false
            return
        }
        lastCmdUpTime = Date()
    }
}
