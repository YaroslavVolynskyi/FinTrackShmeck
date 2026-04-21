import SwiftUI

struct StockTrackerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = PortfolioViewModel()

    private var theme: AppTheme {
        AppTheme.current(for: colorScheme)
    }

    private let tickerWidth: CGFloat = 90
    private let colWidths: [CGFloat] = [82, 72, 90, 100, 120, 80, 86, 82, 82]
    // Columns: Price, Qty, Value, Day G/L, Description, AUM, Mkt Cap, Buy At, Sell At
    private let rowHeight: CGFloat = 48
    private let headerHeight: CGFloat = 32
    @State private var hOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            headerView
            tableCard
        }
        .background(theme.background)
        .scrollDismissesKeyboard(.interactively)
        .onAppear { viewModel.refreshPrices() }
        .alert("Invalid Ticker", isPresented: Binding(
            get: { viewModel.tickerError != nil },
            set: { if !$0 { viewModel.dismissTickerError() } }
        )) {
            Button("OK") { viewModel.dismissTickerError() }
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
                    Text("\(pl >= 0 ? "+" : "-")$\(formatMoney(abs(pl)))")
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
            // Sticky header row (outside vertical scroll)
            HStack(spacing: 0) {
                stickyHeaderCell("Ticker")
                    .frame(width: tickerWidth)
                    .background(theme.surfaceTinted)
                    .zIndex(1)
                GeometryReader { _ in
                    scrollableHeaderRow
                        .background(theme.surfaceTinted)
                        .offset(x: hOffset)
                }
                .clipped()
            }
            .frame(height: headerHeight)
            .background(theme.surfaceTinted)
            .overlay(alignment: .bottom) {
                Rectangle().fill(theme.border).frame(height: 0.5)
            }

            // Vertically scrollable content
            ScrollView(.vertical) {
                HStack(alignment: .top, spacing: 0) {
                    // Ticker column
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.positions.enumerated()), id: \.element.id) { index, _ in
                            stickyTickerDataCell(index: index)
                                .modifier(BlinkModifier(
                                    alertInfo: viewModel.triggeredAlerts[viewModel.positions[index].ticker],
                                    positiveColor: theme.positive,
                                    negativeColor: theme.negative
                                ))
                        }
                        if !viewModel.hasEmptyTicker {
                            newRowTickerCell
                        }
                    }
                    .frame(width: tickerWidth)
                    .background(theme.surfaceTinted)

                    // Horizontally scrollable columns
                    ObservableHScrollView(offset: $hOffset) {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.positions.enumerated()), id: \.element.id) { index, _ in
                                scrollableDataRow(index: index)
                            }
                            if !viewModel.hasEmptyTicker {
                                newRowEmptyCells
                            }
                        }
                    }
                }
            }
        }
        .background(theme.surface)
    }

    // MARK: - Sticky Header Cell

    private func stickyHeaderCell(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundColor(theme.text)
            .frame(width: tickerWidth, height: headerHeight)
    }

    // MARK: - Sticky Ticker Data Cell

    private func stickyTickerDataCell(index: Int) -> some View {
        TickerCell(
            ticker: viewModel.positions[index].ticker,
            name: viewModel.positions[index].name,
            theme: theme,
            width: tickerWidth,
            shouldFocus: viewModel.focusedTickerID == viewModel.positions[index].id,
            onTickerChange: {
                let newTicker = $0.trimmingCharacters(in: .whitespaces).uppercased()
                if newTicker.isEmpty {
                    viewModel.deletePosition(at: index)
                } else {
                    viewModel.positions[index].ticker = newTicker
                    viewModel.validateAndRefreshTicker(at: index)
                }
            },
            onNameChange: { viewModel.positions[index].name = $0 },
            onDelete: { viewModel.deletePosition(at: index) },
            onFocusHandled: { viewModel.focusedTickerID = nil }
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
            headerCell("Description", width: colWidths[4])
            divider()
            headerCell("AUM", width: colWidths[5])
            divider()
            headerCell("Mkt Cap", width: colWidths[6])
            divider()
            headerCell("Buy At", width: colWidths[7])
            divider()
            headerCell("Sell At", width: colWidths[8])
        }
        .frame(height: headerHeight)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.border).frame(height: 0.5)
        }
    }

    private func headerCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundColor(theme.text)
            .frame(width: width, height: headerHeight)
    }

    // MARK: - Scrollable Data Row

    private func scrollableDataRow(index: Int) -> some View {
        let pos = viewModel.positions[index]
        let value = pos.price * pos.shares
        let dayGL = (pos.price - pos.previousClose) * pos.shares
        let dayColor = dayGL >= 0 ? theme.positive : theme.negative
        let dayText = "\(dayGL >= 0 ? "+" : "-")$\(formatMoney(abs(dayGL)))"

        return HStack(spacing: 0) {
            divider()
            EditableCellView(
                value: "$" + String(format: "%.2f", pos.price),
                onCommit: { viewModel.positions[index].price = Double($0.replacingOccurrences(of: "$", with: "")) ?? 0; viewModel.onEdit() },
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
            EditableCellView(
                value: pos.field,
                onCommit: { viewModel.positions[index].field = $0; viewModel.onEdit() },
                alignment: .center, color: theme.muted,
                width: colWidths[4], theme: theme
            )

            divider()
            EditableCellView(
                value: pos.aum,
                onCommit: { viewModel.positions[index].aum = $0; viewModel.onEdit() },
                alignment: .center, isMono: true, color: theme.muted,
                placeholder: "—", width: colWidths[5], theme: theme
            )

            divider()
            EditableCellView(
                value: pos.mcap,
                onCommit: { viewModel.positions[index].mcap = $0; viewModel.onEdit() },
                alignment: .center, isMono: true, color: theme.text,
                width: colWidths[6], theme: theme
            )

            divider()
            EditableCellView(
                value: pos.desiredBuyPrice.map { "$" + String(format: "%.2f", $0) } ?? "",
                onCommit: {
                    let val = Double($0.replacingOccurrences(of: "$", with: ""))
                    viewModel.positions[index].desiredBuyPrice = val
                    viewModel.onEdit()
                },
                alignment: .center, isMono: true, color: theme.positive,
                placeholder: "—", width: colWidths[7], theme: theme
            )

            divider()
            EditableCellView(
                value: pos.requiredSellPrice.map { "$" + String(format: "%.2f", $0) } ?? "",
                onCommit: {
                    let val = Double($0.replacingOccurrences(of: "$", with: ""))
                    viewModel.positions[index].requiredSellPrice = val
                    viewModel.onEdit()
                },
                alignment: .center, isMono: true, color: theme.negative,
                placeholder: "—", width: colWidths[8], theme: theme
            )
        }
        .frame(height: rowHeight)
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
            .frame(width: width, height: rowHeight)
    }

    // MARK: - New Row Empty Cells (scrollable side)

    private var newRowEmptyCells: some View {
        HStack(spacing: 0) {
            ForEach(0..<colWidths.count, id: \.self) { i in
                divider()
                Color.clear.frame(width: colWidths[i], height: rowHeight)
            }
        }
        .frame(height: rowHeight)
        .background(theme.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.border).frame(height: 0.5)
        }
    }

    // MARK: - New Row Ticker Cell

    private var newRowTickerCell: some View {
        HStack(spacing: 4) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
            Text("NEW")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
        }
        .foregroundColor(theme.accent)
        .frame(width: tickerWidth, height: rowHeight)
        .background(theme.surfaceTinted)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.border).frame(height: 0.5)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.addPosition()
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
