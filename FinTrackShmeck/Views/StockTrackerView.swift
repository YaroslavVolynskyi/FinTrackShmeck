import SwiftUI

struct StockTrackerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = PortfolioViewModel()

    private var theme: AppTheme {
        AppTheme.current(for: colorScheme)
    }

    private let tickerWidth: CGFloat = 90
    private let colWidths: [CGFloat] = [82, 72, 90, 100, 100, 120, 80, 86]
    // Columns: Price, Qty, Value, Day G/L, Total G/L, Description, AUM, Mkt Cap

    var body: some View {
        VStack(spacing: 0) {
            headerView
            tableCard
            Spacer().frame(height: 34)
        }
        .background(theme.background)
        .onAppear { viewModel.refreshPrices() }
        .alert("Invalid Ticker", isPresented: Binding(
            get: { viewModel.tickerError != nil },
            set: { if !$0 { viewModel.tickerError = nil } }
        )) {
            Button("OK") { viewModel.tickerError = nil }
        } message: {
            Text(viewModel.tickerError ?? "")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PORTFOLIO · \(viewModel.positions.count) positions")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.muted)
                .tracking(0.4)

            HStack(alignment: .firstTextBaseline) {
                Text("$\(formatMoney(viewModel.totalValue))")
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundColor(theme.text)
                    .tracking(-0.8)

                Spacer()

                HStack(spacing: 4) {
                    let pl = viewModel.dailyPL
                    Text("\(pl >= 0 ? "+" : "")$\(formatMoney(abs(pl)))")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(pl >= 0 ? theme.positive : theme.negative)
                    Text("today")
                        .font(.system(size: 13))
                        .foregroundColor(theme.muted)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Table Card

    private var tableCard: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    tableContent
                    addButton
                }
            }
        }
        .background(theme.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.border).frame(height: 0.5)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.border).frame(height: 0.5)
        }
    }

    // MARK: - Table Content (sticky ticker column + scrollable rest)

    private var tableContent: some View {
        HStack(spacing: 0) {
            // Sticky ticker column
            VStack(spacing: 0) {
                stickyHeaderCell("Ticker")
                ForEach(Array(viewModel.positions.enumerated()), id: \.element.id) { index, _ in
                    stickyTickerDataCell(index: index)
                }
            }
            .frame(width: tickerWidth)
            .background(theme.surface)

            // Scrollable columns
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    scrollableHeaderRow
                    ForEach(Array(viewModel.positions.enumerated()), id: \.element.id) { index, _ in
                        scrollableDataRow(index: index)
                    }
                }
            }
        }
    }

    // MARK: - Sticky Header Cell

    private func stickyHeaderCell(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundColor(theme.faint)
            .frame(width: tickerWidth, height: 32)
            .overlay(alignment: .bottom) {
                Rectangle().fill(theme.border).frame(height: 0.5)
            }
    }

    // MARK: - Sticky Ticker Data Cell

    private func stickyTickerDataCell(index: Int) -> some View {
        TickerCell(
            ticker: viewModel.positions[index].ticker,
            name: viewModel.positions[index].name,
            theme: theme,
            width: tickerWidth,
            onTickerChange: { viewModel.positions[index].ticker = $0.uppercased(); viewModel.validateAndRefreshTicker(at: index) },
            onNameChange: { viewModel.positions[index].name = $0 },
            onDelete: { viewModel.deletePosition(at: index) }
        )
    }

    // MARK: - Scrollable Header Row

    private var scrollableHeaderRow: some View {
        HStack(spacing: 0) {
            divider()
            headerCell("Price", width: colWidths[0])
            divider()
            headerCell("Qty", width: colWidths[1])
            divider()
            headerCell("Value", width: colWidths[2])
            divider()
            headerCell("Day G/L", width: colWidths[3])
            divider()
            headerCell("Total G/L", width: colWidths[4])
            divider()
            headerCell("Description", width: colWidths[5])
            divider()
            headerCell("AUM", width: colWidths[6])
            divider()
            headerCell("Mkt Cap", width: colWidths[7])
        }
        .frame(height: 32)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.border).frame(height: 0.5)
        }
    }

    private func headerCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundColor(theme.faint)
            .frame(width: width, height: 32)
    }

    // MARK: - Scrollable Data Row

    private func scrollableDataRow(index: Int) -> some View {
        let pos = viewModel.positions[index]
        let value = pos.price * pos.shares
        let dayGL = pos.price * (pos.pctChange / 100.0) * pos.shares
        let totalGL = (pos.price - pos.costBasis) * pos.shares
        let dayColor = dayGL >= 0 ? theme.positive : theme.negative
        let dayText = "\(dayGL >= 0 ? "+" : "-")$\(formatMoney(abs(dayGL)))"
        let totalColor = totalGL >= 0 ? theme.positive : theme.negative
        let totalText = "\(totalGL >= 0 ? "+" : "-")$\(formatMoney(abs(totalGL)))"

        return HStack(spacing: 0) {
            divider()
            EditableCellView(
                value: String(format: "%.2f", pos.price),
                onCommit: { viewModel.positions[index].price = Double($0) ?? 0; viewModel.onEdit() },
                alignment: .center, isMono: true, color: theme.text,
                width: colWidths[0], theme: theme
            )

            divider()
            EditableCellView(
                value: String(format: "%.2f", pos.shares),
                onCommit: { viewModel.positions[index].shares = Double($0) ?? 0; viewModel.onEdit() },
                alignment: .center, isMono: true, color: theme.text,
                width: colWidths[1], theme: theme
            )

            divider()
            cell(text: "$\(formatMoney(value))", width: colWidths[2], color: theme.text, mono: true)

            divider()
            cell(text: dayText, width: colWidths[3], color: dayColor, mono: true)

            divider()
            cell(text: totalText, width: colWidths[4], color: totalColor, mono: true)

            divider()
            EditableCellView(
                value: pos.field,
                onCommit: { viewModel.positions[index].field = $0; viewModel.onEdit() },
                alignment: .center, color: theme.muted,
                width: colWidths[5], theme: theme
            )

            divider()
            EditableCellView(
                value: pos.aum,
                onCommit: { viewModel.positions[index].aum = $0; viewModel.onEdit() },
                alignment: .center, isMono: true, color: theme.muted,
                placeholder: "—", width: colWidths[6], theme: theme
            )

            divider()
            EditableCellView(
                value: pos.mcap,
                onCommit: { viewModel.positions[index].mcap = $0; viewModel.onEdit() },
                alignment: .center, isMono: true, color: theme.text,
                width: colWidths[7], theme: theme
            )
        }
        .frame(height: 48)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.border).frame(height: 0.5)
        }
    }

    private func divider() -> some View {
        Rectangle().fill(theme.border).frame(width: 0.5)
    }

    private func cell(text: String, width: CGFloat, color: Color, mono: Bool = false) -> some View {
        Text(text)
            .font(mono ? .system(size: 13, design: .monospaced) : .system(size: 13))
            .foregroundColor(color)
            .lineLimit(1)
            .frame(width: width, height: 48)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button(action: { viewModel.addPosition() }) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14))
                Text("Add position")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(theme.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }


    // MARK: - Helpers

    private func formatMoney(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }
}

#Preview {
    StockTrackerView()
}
