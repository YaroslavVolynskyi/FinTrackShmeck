import SwiftUI

struct EditableCellView: View {
    let value: String
    let onCommit: (String) -> Void
    var alignment: TextAlignment = .center
    var isMono: Bool = false
    var color: Color = .primary
    var fontWeight: Font.Weight = .regular
    var placeholder: String = "—"
    var width: CGFloat = 80
    var theme: AppTheme = .light

    @State private var isEditing = false
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            if isEditing {
                TextField(placeholder, text: $draft)
                    .focused($isFocused)
                    .font(isMono ? .system(size: 13, design: .monospaced) : .system(size: 13))
                    .fontWeight(fontWeight)
                    .foregroundColor(color)
                    .multilineTextAlignment(alignment)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        commitEdit()
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            commitEdit()
                        }
                    }
            } else {
                Text(value.isEmpty ? placeholder : value)
                    .font(isMono ? .system(size: 13, design: .monospaced) : .system(size: 13))
                    .fontWeight(fontWeight)
                    .foregroundColor(value.isEmpty ? theme.faint : color)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: alignment == .trailing ? .trailing : alignment == .center ? .center : .leading as Alignment)
            }
        }
        .padding(.horizontal, 6)
        .frame(width: width, height: 48)
        .background(isEditing ? theme.surface.opacity(0.95) : .clear)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isEditing ? theme.border : .clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            draft = value
            isEditing = true
            isFocused = true
        }
    }

    private func commitEdit() {
        isEditing = false
        if draft != value {
            onCommit(draft)
        }
    }
}
