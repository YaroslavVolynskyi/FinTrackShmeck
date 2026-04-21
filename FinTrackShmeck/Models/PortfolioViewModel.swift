import Foundation
import SwiftUI

@Observable
class PortfolioViewModel {
    var positions: [StockPosition] = PortfolioViewModel.makeSeedData()
    var isRefreshing = false
    var tickerError: String?

    private var refreshTask: Task<Void, Never>?

    var totalValue: Double {
        positions.reduce(0) { $0 + $1.price * $1.shares }
    }

    var dailyPL: Double {
        positions.reduce(0) { sum, pos in
            let changeAmount = pos.price * (pos.pctChange / 100.0) * pos.shares
            return sum + changeAmount
        }
    }

    func addPosition() {
        positions.append(StockPosition())
        scheduleRefresh()
    }

    func deletePosition(at index: Int) {
        guard positions.indices.contains(index) else { return }
        positions.remove(at: index)
    }

    func onEdit() {
        scheduleRefresh()
    }

    func validateAndRefreshTicker(at index: Int) {
        guard positions.indices.contains(index) else { return }
        let ticker = positions[index].ticker
        guard !ticker.isEmpty else { return }

        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            let quotes = await StockService.shared.fetchQuotes(for: [ticker])
            if let quote = quotes[ticker] {
                positions[index].price = quote.price
                positions[index].pctChange = round(quote.pctChange * 100) / 100
                positions[index].dayHigh = quote.dayHigh
                positions[index].dayLow = quote.dayLow
                positions[index].high52w = quote.high52w
                positions[index].low52w = quote.low52w
                if !quote.sparkData.isEmpty {
                    positions[index].sparkData = quote.sparkData
                }
                if positions[index].name.isEmpty {
                    positions[index].name = quote.name
                }
                let vol = quote.volume
                if vol >= 1_000_000 {
                    positions[index].volume = String(format: "%.1fM", Double(vol) / 1_000_000)
                } else if vol >= 1_000 {
                    positions[index].volume = String(format: "%.1fK", Double(vol) / 1_000)
                } else {
                    positions[index].volume = "\(vol)"
                }
                // Refresh all other tickers too
                await fetchAllPrices()
            } else {
                tickerError = "Ticker \"\(ticker)\" not found"
            }
        }
    }

    func refreshPrices() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            await fetchAllPrices()
        }
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await fetchAllPrices()
        }
    }

    @MainActor
    private func fetchAllPrices() async {
        let tickers = positions.compactMap { $0.ticker.isEmpty ? nil : $0.ticker }
        guard !tickers.isEmpty else { return }

        isRefreshing = true
        let quotes = await StockService.shared.fetchQuotes(for: tickers)
        isRefreshing = false

        for i in positions.indices {
            let ticker = positions[i].ticker
            guard let quote = quotes[ticker] else { continue }
            positions[i].price = quote.price
            positions[i].pctChange = round(quote.pctChange * 100) / 100
            positions[i].dayHigh = quote.dayHigh
            positions[i].dayLow = quote.dayLow
            positions[i].high52w = quote.high52w
            positions[i].low52w = quote.low52w
            if !quote.sparkData.isEmpty {
                positions[i].sparkData = quote.sparkData
            }
            if positions[i].name.isEmpty {
                positions[i].name = quote.name
            }
            let vol = quote.volume
            if vol >= 1_000_000 {
                positions[i].volume = String(format: "%.1fM", Double(vol) / 1_000_000)
            } else if vol >= 1_000 {
                positions[i].volume = String(format: "%.1fK", Double(vol) / 1_000)
            } else {
                positions[i].volume = "\(vol)"
            }
        }
    }

    static func makeSeedData() -> [StockPosition] {
        guard let url = Bundle.main.url(forResource: "seed_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let positions = try? JSONDecoder().decode([StockPosition].self, from: data)
        else {
            return []
        }
        return positions
    }
}
