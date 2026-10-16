//
//  GlassPasteButton.swift
//  Clarify
//
//  Created by Sebastian Rogat on 10/13/26.
//

#if os(iOS)
import SwiftUI
import UIKit

/// Apple's system paste control (never shows a permission prompt).
struct GlassPasteButton: UIViewRepresentable {
    let onPaste: (String) -> Void

    func makeUIView(context: Context) -> PasteTargetView {
        PasteTargetView(onPaste: onPaste)
    }

    func updateUIView(_ uiView: PasteTargetView, context: Context) {
        uiView.onPaste = onPaste
    }
}

final class PasteTargetView: UIView {
    var onPaste: (String) -> Void

    init(onPaste: @escaping (String) -> Void) {
        self.onPaste = onPaste
        super.init(frame: .zero)

        // Tells the paste control which kind of content this view accepts: text.
        pasteConfiguration = UIPasteConfiguration(forAccepting: NSString.self)

        let configuration = UIPasteControl.Configuration()
        configuration.displayMode = .iconOnly
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = .tertiarySystemBackground  // white in light mode, dark gray in dark mode
        configuration.baseForegroundColor = .label                     // black in light mode, white in dark mode

        let control = UIPasteControl(configuration: configuration)
        control.target = self
        control.translatesAutoresizingMaskIntoConstraints = false
        addSubview(control)

        NSLayoutConstraint.activate([
            control.leadingAnchor.constraint(equalTo: leadingAnchor),
            control.trailingAnchor.constraint(equalTo: trailingAnchor),
            control.topAnchor.constraint(equalTo: topAnchor),
            control.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    // Called by the system when the paste control is tapped.
    override func paste(itemProviders: [NSItemProvider]) {
        guard let provider = itemProviders.first,
              provider.canLoadObject(ofClass: String.self) else { return }

        _ = provider.loadObject(ofClass: String.self) { @Sendable [weak self] text, _ in
            guard let text else { return }
            Task { @MainActor [weak self] in
                self?.onPaste(text)
            }
        }
    }
}
#endif
