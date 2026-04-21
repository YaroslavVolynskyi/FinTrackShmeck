import Foundation
import SwiftUI

@Observable
class PortfolioViewModel {
    var positions: [StockPosition] = []
    var isRefreshing = false
    var tickerError: String?
    var focusedTickerID: UUID?
    var triggeredAlerts: [String: Bool] = [:]  // ticker -> isBuy
    private var errorTickerID: UUID?
    private var notificationObserver: Any?

    var hasEmptyTicker: Bool {
        positions.contains { $0.ticker.isEmpty }
    }

    private var refreshTask: Task<Void, Never>?
    private var autoRefreshTimer: Timer?

    private static var savedURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("positions.json")
    }

    init() {
        positions = Self.loadPositions()
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .priceAlertReceived, object: nil, queue: .main
        ) { [weak self] notification in
            self?.handlePriceAlert(notification.userInfo)
        }
        startAutoRefresh()
    }

    func startAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            self?.refreshPrices()
        }
    }

    func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }

    private func handlePriceAlert(_ userInfo: [AnyHashable: Any]?) {
        guard let ticker = userInfo?["ticker"] as? String,
              let typeStr = userInfo?["alertType"] as? String else { return }
        let isBuy = typeStr == "buy"
        triggeredAlerts[ticker] = isBuy
        // Auto-clear after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.triggeredAlerts.removeValue(forKey: ticker)
        }
    }

    var totalValue: Double {
        positions.reduce(0) { $0 + $1.price * $1.shares }
    }

    var dailyPL: Double {
        positions.reduce(0) { sum, pos in
            return sum + (pos.price - pos.previousClose) * pos.shares
        }
    }

    func addPosition() {
        let newPosition = StockPosition()
        positions.append(newPosition)
        focusedTickerID = newPosition.id
    }

    func deletePosition(at index: Int) {
        guard positions.indices.contains(index) else { return }
        let ticker = positions[index].ticker
        positions.remove(at: index)
        save()
        if !ticker.isEmpty {
            FirebaseService.shared.removeAlert(ticker: ticker)
        }
    }

    func deletePosition(id: UUID) {
        guard let index = positions.firstIndex(where: { $0.id == id }) else { return }
        deletePosition(at: index)
    }

    func onEdit() {
        save()
        syncToFirebase()
        scheduleRefresh()
    }

    func syncToFirebase() {
        FirebaseService.shared.syncAlerts(positions: positions)
    }

    func sortByValue() {
        let sorted = positions.sorted { ($0.price * $0.shares) > ($1.price * $1.shares) }
        if sorted.map(\.id) != positions.map(\.id) {
            withAnimation(.easeInOut(duration: 0.3)) {
                positions = sorted
            }
        }
    }

    func validateAndRefreshTicker(at index: Int) {
        guard positions.indices.contains(index) else { return }
        let ticker = positions[index].ticker
        guard !ticker.isEmpty else { return }

        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            let quotes = await StockService.shared.fetchQuotes(for: [ticker])
            if let quote = quotes[ticker] {
                applyQuote(quote, at: index)
                save()
                await fetchAllPrices()
            } else {
                errorTickerID = positions[index].id
                tickerError = "Ticker \"\(ticker)\" not found"
            }
        }
    }

    func dismissTickerError() {
        tickerError = nil
        if let id = errorTickerID {
            focusedTickerID = id
            errorTickerID = nil
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
            guard let quote = quotes[positions[i].ticker] else { continue }
            applyQuote(quote, at: i)
        }
        sortByValue()
        save()
    }

    private func applyQuote(_ quote: StockQuote, at index: Int) {
        positions[index].price = quote.price
        positions[index].previousClose = quote.previousClose
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
    }

    // MARK: - Persistence

    func save() {
        let validPositions = positions.filter { !$0.ticker.isEmpty }
        guard let data = try? JSONEncoder().encode(validPositions) else { return }
        try? data.write(to: Self.savedURL)
    }

    private static func loadPositions() -> [StockPosition] {
        // Try loading saved data first
        if let data = try? Data(contentsOf: savedURL),
           let positions = try? JSONDecoder().decode([StockPosition].self, from: data),
           !positions.isEmpty {
            return positions
        }
        // Fall back to seed data
        guard let url = Bundle.main.url(forResource: "seed_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let positions = try? JSONDecoder().decode([StockPosition].self, from: data)
        else {
            return []
        }
        return positions
    }
}
