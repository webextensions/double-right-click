// Send real mouse and keyboard input on macOS through Quartz events (CGEvent), with the same commands as
// real_input.py (which does the same through GNOME's RemoteDesktop D-Bus API on Linux).
//
// Requirements: macOS with the Xcode Command Line Tools (swiftc), and the Accessibility permission for the app which
// runs it (eg: Visual Studio Code or Terminal: System Settings > Privacy & Security > Accessibility). Without that
// permission macOS drops the events silently, so this stops with an error instead.
//
// Usage: swiftc -O -o real_input_mac scripts/real-input/real_input_mac.swift
//        ./real_input_mac <command> [arguments] [<command> [arguments] ...]
//
// Commands, run in the given order:
//
// - move X Y - move the pointer to X, Y on the screen (in points, as the browser's screenX and screenY)
// - rel DX DY - move the pointer by DX, DY
// - left - left click
// - right - right click
// - right-hold S - right click which keeps the button down for S seconds
// - esc - press Escape
// - shift-down / shift-up, ctrl-down / ctrl-up, alt-down / alt-up - press / release Shift, Control or Option
//   (released at the end in any case)
// - sleep S - wait S seconds

import AppKit
import ApplicationServices

struct ModifierKey {
    let keyCode: CGKeyCode
    let flag: CGEventFlags
}

let modifierKeys: [String: ModifierKey] = [
    "shift": ModifierKey(keyCode: 56, flag: .maskShift),
    "ctrl": ModifierKey(keyCode: 59, flag: .maskControl),
    "alt": ModifierKey(keyCode: 58, flag: .maskAlternate)
]
let escapeKeyCode: CGKeyCode = 53

func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(1)
}

func pause(_ seconds: Double) {
    Thread.sleep(forTimeInterval: seconds)
}

final class Input {
    private let source = CGEventSource(stateID: .hidSystemState)
    private var heldKeys: [String] = []
    // A click soon after another one of the same button, on about the same spot, gets the next click count (2 for a
    // double click), as the events of a real mouse do: the browser reads it as the "detail" of the events
    private var lastClick: (button: CGMouseButton, time: Date, location: CGPoint, count: Int64)?

    private var flags: CGEventFlags {
        var flags: CGEventFlags = []
        for key in heldKeys {
            flags.insert(modifierKeys[key]!.flag)
        }
        return flags
    }

    var location: CGPoint {
        return CGEvent(source: nil)?.location ?? .zero
    }

    private func post(_ event: CGEvent?) {
        guard let event = event else {
            fail("Could not create an input event")
        }
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }

    func moveTo(_ point: CGPoint) {
        post(CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left))
        pause(0.1)
    }

    func moveBy(_ dx: Double, _ dy: Double) {
        let from = location
        moveTo(CGPoint(x: from.x + dx, y: from.y + dy))
    }

    func click(_ button: CGMouseButton, holdSeconds: Double = 0.03) {
        let point = location
        let now = Date()
        var count: Int64 = 1
        if let last = lastClick,
           last.button == button,
           now.timeIntervalSince(last.time) <= NSEvent.doubleClickInterval,
           abs(last.location.x - point.x) <= 4,
           abs(last.location.y - point.y) <= 4 {
            count = last.count + 1
        }
        lastClick = (button, now, point, count)
        let (downType, upType): (CGEventType, CGEventType) = button == .right ?
            (.rightMouseDown, .rightMouseUp) :
            (.leftMouseDown, .leftMouseUp)
        for (type, wait) in [(downType, holdSeconds), (upType, 0.0)] {
            let event = CGEvent(
                mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: button
            )
            event?.setIntegerValueField(.mouseEventClickState, value: count)
            post(event)
            pause(wait)
        }
    }

    func key(_ keyCode: CGKeyCode) {
        for down in [true, false] {
            post(CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down))
            pause(0.02)
        }
    }

    func modifier(_ name: String, down: Bool) {
        if down {
            if !heldKeys.contains(name) {
                heldKeys.append(name)
            }
        } else {
            heldKeys.removeAll { $0 == name }
        }
        // The flags of the event tell whether the key is now down
        post(CGEvent(keyboardEventSource: source, virtualKey: modifierKeys[name]!.keyCode, keyDown: down))
        pause(0.02)
    }

    func releaseHeldKeys() {
        for name in heldKeys {
            modifier(name, down: false)
        }
    }
}

func number(_ commands: [String], _ index: Int) -> Double {
    guard index < commands.count, let value = Double(commands[index]) else {
        fail("Expected a number after \"\(commands[index - 1])\"")
    }
    return value
}

let commands = Array(CommandLine.arguments.dropFirst())

if !AXIsProcessTrusted() {
    fail("""
    macOS drops input events from apps without the Accessibility permission. Allow the app which runs this (eg: \
    Visual Studio Code or Terminal) in System Settings > Privacy & Security > Accessibility, then run it again.
    """)
}

let input = Input()
// A key left held down would stay held on the desktop
signal(SIGINT) { _ in
    input.releaseHeldKeys()
    exit(130)
}
var index = 0
while index < commands.count {
    let command = commands[index]
    switch command {
    case "move":
        input.moveTo(CGPoint(x: number(commands, index + 1), y: number(commands, index + 2)))
        index += 3
    case "rel":
        input.moveBy(number(commands, index + 1), number(commands, index + 2))
        index += 3
    case "left":
        input.click(.left)
        index += 1
    case "right":
        input.click(.right)
        index += 1
    case "right-hold":
        input.click(.right, holdSeconds: number(commands, index + 1))
        index += 2
    case "esc":
        input.key(escapeKeyCode)
        index += 1
    case "sleep":
        pause(number(commands, index + 1))
        index += 2
    default:
        let parts = command.split(separator: "-").map(String.init)
        if parts.count == 2, modifierKeys[parts[0]] != nil, parts[1] == "down" || parts[1] == "up" {
            input.modifier(parts[0], down: parts[1] == "down")
            index += 1
        } else {
            input.releaseHeldKeys()
            fail("Unknown command \"\(command)\"")
        }
    }
}
input.releaseHeldKeys()
