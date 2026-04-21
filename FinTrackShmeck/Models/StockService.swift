import Foundation

struct StockQuote {
    let symbol: String
    let price: Double
    let pctChange: Double
    let dayHigh: Double
    let dayLow: Double
    let high52w: Double
    let low52w: Double
    let volume: Int
    let name: String
    let sparkData: [Double]
}

class StockService {
    static let shared = StockService()
    private init() {}

    func fetchQuotes(for tickers: [String]) async -> [String: StockQuote] {
        var results: [String: StockQuote] = [:]

        await withTaskGroup(of: (String, StockQuote?).self) { group in
            for ticker in tickers where !ticker.isEmpty {
                group.addTask {
                    let quote = await self.fetchSingle(ticker: ticker)
                    return (ticker, quote)
                }
            }
            for await (ticker, quote) in group {
                if let quote = quote {
                    results[ticker] = quote
                }
            }
        }

        return results
    }

    private func fetchSingle(ticker: String) async -> StockQuote? {
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(ticker)?interval=1d&range=5d"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chart = json["chart"] as? [String: Any],
              let resultArray = chart["result"] as? [[String: Any]],
              let result = resultArray.first,
              let meta = result["meta"] as? [String: Any],
              let price = meta["regularMarketPrice"] as? Double
        else { return nil }

        let prevClose = meta["chartPreviousClose"] as? Double ?? price
        let pctChange = prevClose > 0 ? ((price - prevClose) / prevClose) * 100.0 : 0
        let dayHigh = meta["regularMarketDayHigh"] as? Double ?? 0
        let dayLow = meta["regularMarketDayLow"] as? Double ?? 0
        let high52w = meta["fiftyTwoWeekHigh"] as? Double ?? 0
        let low52w = meta["fiftyTwoWeekLow"] as? Double ?? 0
        let volume = meta["regularMarketVolume"] as? Int ?? 0
        let name = meta["longName"] as? String ?? meta["shortName"] as? String ?? ticker

        var sparkData: [Double] = []
        if let indicators = result["indicators"] as? [String: Any],
           let quoteArray = indicators["quote"] as? [[String: Any]],
           let quote = quoteArray.first,
           let closes = quote["close"] as? [Double?] {
            sparkData = closes.compactMap { $0 }
        }

        return StockQuote(
            symbol: ticker,
            price: price,
            pctChange: pctChange,
            dayHigh: dayHigh,
            dayLow: dayLow,
            high52w: high52w,
            low52w: low52w,
            volume: volume,
            name: name,
            sparkData: sparkData
        )
    }
}
