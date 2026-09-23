//
// FixedOrientation.swift
// RetroCartridge
//
// Pins a layout to the physical display so it never appears to rotate.
//
// The app supports every interface orientation (otherwise iOS letterboxes
// and rotates it as a whole) and its root view controller locks the scene's
// orientation (see `ConsoleHostingController`), so the system never rotates
// it. Whatever orientation a display's scene is locked in, the content is
// turned to the design orientation for that display.
//

import SwiftUI
import UIKit

/// Draws `content` as if the interface were in `design` orientation,
/// whatever orientation the system is actually using.
struct FixedOrientation<Content: View>: View {
    let design: UIInterfaceOrientation
    
    /// When false the content fills the whole display and reads the remapped
    /// insets from `\.fixedSafeAreaInsets` to apply them itself, e.g. to keep
    /// a split aligned with the hinge.
    var padsSafeArea: Bool = true
    
    /// When true, a scene locked upside down relative to `design` is drawn
    /// without the 180° counter-turn. On the iPhone Duo inner display, a
    /// scene locked to `.portraitUpsideDown` appears the same way up as one
    /// locked to `.portrait` (observed on the iOS 27 simulator), so turning
    /// it would show the console upside down.
    var ignoresHalfTurns: Bool = false
    
    @ViewBuilder var content: Content

    /// The scene's interface orientation; nil until the reader has reported
    /// it, so a frame is never drawn turned the wrong way.
    @State private var current: UIInterfaceOrientation?

    var body: some View {
        GeometryReader { geo in
            let rawTurn = Self.quarterTurns(from: current ?? design, to: design)
            let turn = ignoresHalfTurns && rawTurn == 2 ? 0 : rawTurn
            let size = geo.size
            let insets = geo.safeAreaInsets
            let isSideways = turn % 2 != 0

            let contentInsets = Self.contentInsets(insets, quarterTurns: turn)
            
            content
                .ignoresSafeArea()
                .environment(\.fixedSafeAreaInsets, contentInsets)
                .padding(padsSafeArea ? contentInsets : EdgeInsets())
                .frame(
                    width: isSideways ? size.height : size.width,
                    height: isSideways ? size.width : size.height
                )
                .rotationEffect(.degrees(Double(turn) * 90))
                .frame(width: size.width, height: size.height)
                .opacity(current == nil ? 0 : 1)
        }
        .ignoresSafeArea()
        .background {
            InterfaceOrientationReader(orientation: $current)
        }
    }

    /// Clockwise angle, in quarter turns, of an interface orientation's "up"
    /// relative to the display's native portrait "up".
    private static func quarterTurns(of orientation: UIInterfaceOrientation) -> Int {
        switch orientation {
        case .landscapeLeft: return 3   // up points at the display's left edge
        case .landscapeRight: return 1  // up points at the display's right edge
        case .portraitUpsideDown: return 2
        default: return 0
        }
    }

    /// Clockwise quarter turns (0...3) that take content laid out for the
    /// current interface to the design orientation.
    private static func quarterTurns(from current: UIInterfaceOrientation, to design: UIInterfaceOrientation) -> Int {
        ((quarterTurns(of: design) - quarterTurns(of: current)) % 4 + 4) % 4
    }

    /// Maps the container's safe area insets onto the edges of content that
    /// will be rotated clockwise by `quarterTurns`.
    private static func contentInsets(_ i: EdgeInsets, quarterTurns: Int) -> EdgeInsets {
        switch quarterTurns {
        case 1: // content top ends up on the container's trailing edge
            return EdgeInsets(top: i.trailing, leading: i.top, bottom: i.leading, trailing: i.bottom)
        case 2:
            return EdgeInsets(top: i.bottom, leading: i.trailing, bottom: i.top, trailing: i.leading)
        case 3: // content top ends up on the container's leading edge
            return EdgeInsets(top: i.leading, leading: i.bottom, bottom: i.trailing, trailing: i.top)
        default:
            return i
        }
    }
}

extension EnvironmentValues {
    /// Safe area insets of a `FixedOrientation` container, mapped onto the
    /// edges of its (rotated) content.
    @Entry var fixedSafeAreaInsets = EdgeInsets()
}

// MARK: - Interface orientation

/// Publishes the window scene's interface orientation.
private struct InterfaceOrientationReader: UIViewRepresentable {
    @Binding var orientation: UIInterfaceOrientation?
    
    func makeUIView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.isUserInteractionEnabled = false
        view.onChange = { orientation = $0 }
        return view
    }
    
    func updateUIView(_ uiView: ReaderView, context: Context) {
        uiView.onChange = { orientation = $0 }
    }
    
    final class ReaderView: UIView {
        var onChange: ((UIInterfaceOrientation) -> Void)?
        private var observation: NSKeyValueObservation?
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            observation = nil
            guard let scene = window?.windowScene else { return }
            
            onChange?(scene.effectiveGeometry.interfaceOrientation)
            observation = scene.observe(\.effectiveGeometry, options: [.new]) { [weak self] scene, _ in
                MainActor.assumeIsolated {
                    self?.onChange?(scene.effectiveGeometry.interfaceOrientation)
                }
            }
        }
    }
}
