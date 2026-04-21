import SwiftUI

struct TickerCell: View {
    let ticker: String
    let name: String
    let theme: AppTheme
    let width: CGFloat
    var shouldFocus: Bool = false
    let onTickerChange: (String) -> Void
    let onNameChange: (String) -> Void
    let onDelete: () -> Void
    var onFocusHandled: (() -> Void)? = nil

    @State private var isEditingTicker = false
    @State private var tickerDraft = ""
    @State private var isEditingName = false
    @State private var nameDraft = ""
    @FocusState private var tickerFocused: Bool
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: 2) {
            if isEditingTicker {
                TextField("TICK", text: $tickerDraft)
                    .focused($tickerFocused)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.characters)
                    .onSubmit { commitTicker() }
                    .onChange(of: tickerFocused) { _, focused in
                        if !focused { commitTicker() }
                    }
            } else {
                Text(ticker.isEmpty ? "TICK" : ticker)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(ticker.isEmpty ? theme.faint : theme.text)
                    .onTapGesture {
                        tickerDraft = ticker
                        isEditingTicker = true
                        tickerFocused = true
                    }
            }

            if isEditingName {
                TextField("Name", text: $nameDraft)
                    .focused($nameFocused)
                    .font(.system(size: 9))
                    .foregroundColor(theme.muted)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .onSubmit { commitName() }
                    .onChange(of: nameFocused) { _, focused in
                        if !focused { commitName() }
                    }
            } else {
                Text(name.isEmpty ? "—" : name)
                    .font(.system(size: 9))
                    .foregroundColor(theme.muted)
                    .lineLimit(1)
                    .onTapGesture {
                        nameDraft = name
                        isEditingName = true
                        nameFocused = true
                    }
            }
        }
        .frame(width: width, height: 48)
        .background(theme.surfaceTinted)
        .contextMenu {
            Button(role: .destructive, action: { withAnimation { onDelete() } }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.border).frame(height: 0.5)
        }
        .onAppear {
            if shouldFocus { activateFocus() }
        }
        .onChange(of: shouldFocus) { _, focus in
            if focus { activateFocus() }
        }
    }

    private func commitTicker() {
        isEditingTicker = false
        onTickerChange(tickerDraft)
    }

    private func commitName() {
        isEditingName = false
        if nameDraft != name { onNameChange(nameDraft) }
    }

    private func activateFocus() {
        tickerDraft = ticker
        isEditingTicker = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            tickerFocused = true
        }
        onFocusHandled?()
    }
}
