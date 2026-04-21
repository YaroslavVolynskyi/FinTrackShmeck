import SwiftUI

struct StockTrackerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = PortfolioViewModel()

    private var theme: AppTheme {
        AppTheme.current(for: colorScheme)
    }

    private let tickerWidth: CGFloat = 100
    private let colWidth: CGFloat = 82

    var body: some View {
        VStack(spacing: 0) {
            headerView
            tableCard
            Spacer().frame(height: 34)
        }
        .background(theme.background)
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
                    Text("+$\(formatMoney(viewModel.dailyPL))")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.positive)
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
                    // Header row
                    headerRow
                    // Data rows
                    ForEach(Array(viewModel.positions.enumerated()), id: \.element.id) { index, _ in
                        dataRow(index: index)
                        Divider().background(theme.border)
                    }
                    // Add position button
                    addButton
                }
            }

            scrollHint
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.border, lineWidth: 0.5)
        )
        .padding(.horizontal, 12)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                headerCell("Ticker", width: tickerWidth)
                headerCell("Price", width: colWidth, align: .trailing)
                headerCell("%", width: 80, align: .trailing)
                headerCell("7d", width: 68)
                headerCell("Shares", width: 68, align: .trailing)
                headerCell("Sector", width: 116)
                headerCell("AUM", width: 72, align: .trailing)
                headerCell("Mkt Cap", width: 76, align: .trailing)
                headerCell("Day High", width: colWidth, align: .trailing)
                headerCell("Day Low", width: colWidth, align: .trailing)
                headerCell("52W High", width: 86, align: .trailing)
                headerCell("52W Low", width: 86, align: .trailing)
                headerCell("Volume", width: 76, align: .trailing)
                headerCell("P/E", width: 62, align: .trailing)
                headerCell("Div Yld", width: 76, align: .trailing)
                headerCell("Cost", width: colWidth, align: .trailing)
            }
        }
        .frame(height: 32)
        .background(theme.surface)
        .overlay(alignment: .bottom) {
            Divider().background(theme.border)
        }
    }

    private func headerCell(_ title: String, width: CGFloat, align: Alignment = .leading) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundColor(theme.faint)
            .frame(width: width, height: 32, alignment: align)
            .padding(.horizontal, 10)
    }

    // MARK: - Data Row

    private func dataRow(index: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // Ticker column
                tickerCell(index: index)

                // Price
                EditableCellView(
                    value: String(format: "%.2f", viewModel.positions[index].price),
                    onCommit: { viewModel.positions[index].price = Double($0) ?? 0 },
                    alignment: .trailing, isMono: true, color: theme.text,
                    width: colWidth, theme: theme
                )

                // % Change
                let pct = viewModel.positions[index].pctChange
                let isUp = pct >= 0
                EditableCellView(
                    value: "\(isUp ? "+" : "")\(String(format: "%.2f", pct))%",
                    onCommit: { viewModel.positions[index].pctChange = Double($0.replacingOccurrences(of: "%", with: "").replacingOccurrences(of: "+", with: "")) ?? 0 },
                    alignment: .trailing, isMono: true, color: isUp ? theme.positive : theme.negative,
                    fontWeight: .medium, width: 80, theme: theme
                )

                // Sparkline
                SparklineView(
                    data: viewModel.positions[index].sparkData,
                    isPositive: isUp,
                    theme: theme
                )
                .frame(width: 68)
                .padding(.horizontal, 6)

                // Shares
                EditableCellView(
                    value: "\(viewModel.positions[index].shares)",
                    onCommit: { viewModel.positions[index].shares = Int($0) ?? 0 },
                    alignment: .trailing, isMono: true, color: theme.text,
                    width: 68, theme: theme
                )

                // Sector
                EditableCellView(
                    value: viewModel.positions[index].field,
                    onCommit: { viewModel.positions[index].field = $0 },
                    color: theme.muted, width: 116, theme: theme
                )

                // AUM
                EditableCellView(
                    value: viewModel.positions[index].aum,
                    onCommit: { viewModel.positions[index].aum = $0 },
                    alignment: .trailing, isMono: true, color: theme.muted,
                    placeholder: "—", width: 72, theme: theme
                )

                // Market Cap
                EditableCellView(
                    value: viewModel.positions[index].mcap,
                    onCommit: { viewModel.positions[index].mcap = $0 },
                    alignment: .trailing, isMono: true, color: theme.text,
                    width: 76, theme: theme
                )

                // Day High
                EditableCellView(
                    value: String(format: "%.2f", viewModel.positions[index].dayHigh),
                    onCommit: { viewModel.positions[index].dayHigh = Double($0) ?? 0 },
                    alignment: .trailing, isMono: true, color: theme.text,
                    width: colWidth, theme: theme
                )

                // Day Low
                EditableCellView(
                    value: String(format: "%.2f", viewModel.positions[index].dayLow),
                    onCommit: { viewModel.positions[index].dayLow = Double($0) ?? 0 },
                    alignment: .trailing, isMono: true, color: theme.text,
                    width: colWidth, theme: theme
                )

                // 52W High
                EditableCellView(
                    value: String(format: "%.2f", viewModel.positions[index].high52w),
                    onCommit: { viewModel.positions[index].high52w = Double($0) ?? 0 },
                    alignment: .trailing, isMono: true, color: theme.muted,
                    width: 86, theme: theme
                )

                // 52W Low
                EditableCellView(
                    value: String(format: "%.2f", viewModel.positions[index].low52w),
                    onCommit: { viewModel.positions[index].low52w = Double($0) ?? 0 },
                    alignment: .trailing, isMono: true, color: theme.muted,
                    width: 86, theme: theme
                )

                // Volume
                EditableCellView(
                    value: viewModel.positions[index].volume,
                    onCommit: { viewModel.positions[index].volume = $0 },
                    alignment: .trailing, isMono: true, color: theme.muted,
                    width: 76, theme: theme
                )

                // P/E
                EditableCellView(
                    value: String(format: "%.1f", viewModel.positions[index].pe),
                    onCommit: { viewModel.positions[index].pe = Double($0) ?? 0 },
                    alignment: .trailing, isMono: true, color: theme.text,
                    width: 62, theme: theme
                )

                // Div Yield
                EditableCellView(
                    value: viewModel.positions[index].divYield,
                    onCommit: { viewModel.positions[index].divYield = $0 },
                    alignment: .trailing, isMono: true, color: theme.muted,
                    width: 76, theme: theme
                )

                // Cost Basis
                EditableCellView(
                    value: String(format: "%.2f", viewModel.positions[index].costBasis),
                    onCommit: { viewModel.positions[index].costBasis = Double($0) ?? 0 },
                    alignment: .trailing, isMono: true, color: theme.muted,
                    width: colWidth, theme: theme
                )
            }
        }
    }

    private func tickerCell(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            EditableCellView(
                value: viewModel.positions[index].ticker,
                onCommit: { viewModel.positions[index].ticker = $0.uppercased() },
                isMono: true, color: theme.text, fontWeight: .semibold,
                placeholder: "TICK", width: 80, theme: theme
            )
            Text(viewModel.positions[index].name.isEmpty ? "—" : viewModel.positions[index].name)
                .font(.system(size: 10))
                .foregroundColor(theme.muted)
                .lineLimit(1)
                .padding(.horizontal, 10)
        }
        .frame(width: tickerWidth)
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

    // MARK: - Scroll Hint

    private var scrollHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 8))
            Text("SCROLL BOTH DIRECTIONS")
                .font(.system(size: 10, weight: .regular))
                .tracking(0.5)
        }
        .foregroundColor(theme.faint)
        .frame(height: 26)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            Divider().background(theme.border)
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
