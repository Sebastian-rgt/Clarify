//
//  LookUpView.swift
//  Clarify
//
//  Created by Sebastian Rogat on 10/13/26.
//

import SwiftUI

enum LookupMode: String, CaseIterable, Identifiable {
    case clarify = "Clarify"
    case translate = "Translate"
    case pronounce = "Pronounce"

    var id: Self { self }

    var placeholder: String {
        switch self {
        case .clarify: "Enter a word or phrase"
        case .translate: "Enter text to translate"
        case .pronounce: "Enter text to pronounce"
        }
    }
}

struct LookUpView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedMode: LookupMode = .clarify
    @State private var inputText = ""
    @State private var submittedQuery = ""
    @State private var results: [LookupMode: String] = [:]
    @State private var loadingModes: Set<LookupMode> = []
    @State private var showSettings = false
    @State private var clipboardHasText = true
    @FocusState private var isInputFocused: Bool
    @Namespace private var glassNamespace
    var focusRequest = 0

    private enum Metrics {
        static let controlHeight: CGFloat = 44
        static let outerSpacing: CGFloat = 12
        static let innerSpacing: CGFloat = 8
        static let fieldPadding: CGFloat = 14
    }

    private var trimmedInput: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                inputBar
                modePicker
                resultArea
                Spacer(minLength: 0)
            }
            .padding(.top)
            .navigationTitle("Look Up")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Settings", systemImage: "gear") {
                        showSettings = true
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                Text("Prompt Settings")
                    .padding()
                    .presentationSizing(.form)
            }
            .onChange(of: selectedMode) {
                if !isInputFocused && !trimmedInput.isEmpty {
                    submit()
                }
            }
            .onAppear(perform: refreshClipboardState)
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    refreshClipboardState()
                }
            }
            .onChange(of: focusRequest) {
                isInputFocused = true
            }
            #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
                refreshClipboardState()
            }
            #endif
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        GlassEffectContainer(spacing: Metrics.outerSpacing) {
            HStack(spacing: Metrics.outerSpacing) {
                if !isInputFocused && clipboardHasText {
                    pasteButton
                }

                searchField

                if isInputFocused {
                    Button {
                        inputText = ""
                        isInputFocused = false
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.primary)
                            .frame(width: Metrics.controlHeight, height: Metrics.controlHeight)
                            .contentShape(.circle)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .glassEffectID("cancel", in: glassNamespace)
                }
            }
        }
        .padding(.horizontal)
        .animation(.snappy, value: isInputFocused)
        .animation(.snappy, value: clipboardHasText)
    }

    @ViewBuilder
    private var pasteButton: some View {
        #if os(iOS)
        GlassPasteButton(onPaste: handlePaste)
            .id(colorScheme)  // rebuild when light/dark changes, so its colors update
            .frame(width: Metrics.controlHeight, height: Metrics.controlHeight)
            .glassEffect(.regular.interactive(), in: .circle)
            .glassEffectID("paste", in: glassNamespace)
        #else
        PasteButton(payloadType: String.self) { strings in
            if let text = strings.first {
                handlePaste(text)
            }
        }
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        .controlSize(.extraLarge)
        .buttonStyle(.glass)
        #endif
    }

    private var searchField: some View {
        HStack(spacing: Metrics.innerSpacing) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.primary)

            TextField(selectedMode.placeholder, text: $inputText)
                .textFieldStyle(.plain)
                .focused($isInputFocused)
                .submitLabel(.go)
                .onSubmit(submit)

            Group {
                if inputText.isEmpty {
                    Button("Dictate", systemImage: "mic.fill", action: startDictation)
                } else {
                    Button("Clear", systemImage: "xmark.circle.fill") {
                        inputText = ""
                        isInputFocused = true
                    }
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, Metrics.fieldPadding)
        .frame(height: Metrics.controlHeight)
        .glassEffect(.regular.interactive(), in: .capsule)
        .glassEffectID("field", in: glassNamespace)
        .contentShape(.capsule)
        .onTapGesture { isInputFocused = true }
    }

    // MARK: - Mode picker

    private var modePicker: some View {
        Picker("Mode", selection: $selectedMode) {
            ForEach(LookupMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .glassEffect()
        .padding(.horizontal)
    }

    // MARK: - Result

    @ViewBuilder
    private var resultArea: some View {
        if loadingModes.contains(selectedMode) {
            ProgressView()
                .controlSize(.large)
                .padding(.top, 24)
        } else if let result = results[selectedMode] {
            ScrollView {
                Text(result)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 20))
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func refreshClipboardState() {
        #if os(iOS)
        clipboardHasText = UIPasteboard.general.hasStrings
        #endif
    }

    private func handlePaste(_ text: String) {
        let pasted = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pasted.isEmpty else { return }
        inputText = pasted
        submit()
    }

    private func submit() {
        let query = trimmedInput
        guard !query.isEmpty else { return }
        isInputFocused = false

        // A new query starts fresh: forget the answers to the previous one.
        if query != submittedQuery {
            submittedQuery = query
            results = [:]
            loadingModes = []
        }

        let mode = selectedMode
        // Already have this mode's answer, or already fetching it? Just show it.
        guard results[mode] == nil, !loadingModes.contains(mode) else { return }

        loadingModes.insert(mode)

        // Placeholder: pretends to wait for the AI. Replaced by real calls next.
        Task {
            try? await Task.sleep(for: .seconds(1))
            guard submittedQuery == query else { return }  // user moved on to a new query
            results[mode] = "\(mode.rawValue) result for “\(query)” will appear here."
            loadingModes.remove(mode)
        }
    }

    private func startDictation() {
        // Speech recognition comes later.
    }
}

#Preview {
    LookUpView()
}

#if os(iOS)
#Preview("Search scopes test") {
    @Previewable @State var text = ""
    @Previewable @State var mode: LookupMode = .clarify
    NavigationStack {
        Text("Results go here")
            .navigationTitle("Look Up")
            .searchable(text: $text,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Enter a word or phrase")
            .searchScopes($mode, activation: .onSearchPresentation) {
                ForEach(LookupMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
    }
}
#endif
