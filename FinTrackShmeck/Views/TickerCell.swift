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

    private var logoURL: URL? {
        guard !ticker.isEmpty, ticker != "GLD" else { return nil }
        return URL(string: "https://financialmodelingprep.com/image-stock/\(ticker).png")
    }

    private var isGold: Bool { ticker == "GLD" }

    var body: some View {
        ZStack(alignment: .leading) {
            // Logo pinned left
            if !ticker.isEmpty {
                if isGold {
                    Text("GLD")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13))
                        .frame(width: 22, height: 22)
                        .background(Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(.leading, 6)
                } else {
                    AsyncImage(url: logoURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        default:
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.border)
                                .frame(width: 22, height: 22)
                        }
                    }
                    .padding(.leading, 6)
                }
            }

            // Ticker + Name centered
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
            .padding(.leading, ticker.isEmpty ? 0 : 28)
            .frame(width: width)
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
