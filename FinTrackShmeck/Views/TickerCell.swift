import SwiftUI

struct TickerCell: View {
    let ticker: String
    let name: String
    let theme: AppTheme
    let width: CGFloat
    let onTickerChange: (String) -> Void
    let onNameChange: (String) -> Void
    let onDelete: () -> Void

    @State private var isEditingTicker = false
    @State private var tickerDraft = ""
    @State private var isEditingName = false
    @State private var nameDraft = ""
    @State private var offset: CGFloat = 0
    @State private var showDelete = false
    @FocusState private var tickerFocused: Bool
    @FocusState private var nameFocused: Bool

    private let deleteWidth: CGFloat = 70

    var body: some View {
        ZStack(alignment: .leading) {
            // Delete button behind
            HStack {
                Button(action: performDelete) {
                    Text("Delete")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: deleteWidth, height: 48)
                        .background(Color.red)
                }
                Spacer()
            }

            // Main cell content
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
            .background(theme.surface)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let translation = value.translation.width
                        if translation < 0 {
                            offset = max(translation, -deleteWidth)
                        } else if showDelete {
                            offset = min(translation - deleteWidth, 0)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.easeOut(duration: 0.2)) {
                            if value.translation.width < -deleteWidth / 2 {
                                offset = -deleteWidth
                                showDelete = true
                            } else {
                                offset = 0
                                showDelete = false
                            }
                        }
                    }
            )
            .contextMenu {
                Button(role: .destructive, action: performDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .frame(width: width, height: 48)
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.border).frame(height: 0.5)
        }
    }

    private func commitTicker() {
        isEditingTicker = false
        if tickerDraft != ticker { onTickerChange(tickerDraft) }
    }

    private func commitName() {
        isEditingName = false
        if nameDraft != name { onNameChange(nameDraft) }
    }

    private func performDelete() {
        withAnimation { onDelete() }
    }
}
