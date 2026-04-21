import Foundation
import SwiftUI

@Observable
class PortfolioViewModel {
    var positions: [StockPosition] = PortfolioViewModel.makeSeedData()

    var totalValue: Double {
        positions.reduce(0) { $0 + $1.price * Double($1.shares) }
    }

    var dailyPL: Double {
        positions.reduce(0) { sum, pos in
            let changeAmount = pos.price * (pos.pctChange / 100.0) * Double(pos.shares)
            return sum + changeAmount
        }
    }

    func addPosition() {
        positions.append(StockPosition())
    }

    static func makeSeedData() -> [StockPosition] {
        [
            StockPosition(ticker: "NVDL", name: "Nividul Systems", price: 842.31, shares: 42, field: "Semiconductors", aum: "—", mcap: "2.08T", pctChange: 1.82, dayHigh: 848.20, dayLow: 830.11, high52w: 912.40, low52w: 410.22, volume: "38.2M", pe: 62.4, divYield: "0.04%", costBasis: 612.00, sparkData: [31,33,30,34,36,35,38,40,39,42,44,43]),
            StockPosition(ticker: "ARVX", name: "Arvex Therapeutics", price: 118.04, shares: 120, field: "Biotech", aum: "—", mcap: "412B", pctChange: -0.64, dayHigh: 120.80, dayLow: 117.22, high52w: 144.10, low52w: 88.40, volume: "12.1M", pe: 28.2, divYield: "—", costBasis: 96.50, sparkData: [28,27,29,26,25,27,24,22,24,21,20,22]),
            StockPosition(ticker: "HLSN", name: "Halsen Energy", price: 54.88, shares: 310, field: "Energy", aum: "—", mcap: "88B", pctChange: 3.41, dayHigh: 55.21, dayLow: 52.90, high52w: 62.15, low52w: 38.02, volume: "22.6M", pe: 14.1, divYield: "3.80%", costBasis: 42.10, sparkData: [10,12,14,13,16,18,17,20,22,21,24,27]),
            StockPosition(ticker: "KRFT", name: "Kraftos Capital", price: 312.60, shares: 18, field: "Asset Mgmt", aum: "1.4T", mcap: "196B", pctChange: 0.22, dayHigh: 314.00, dayLow: 309.50, high52w: 338.77, low52w: 218.11, volume: "3.4M", pe: 18.6, divYield: "2.10%", costBasis: 280.40, sparkData: [22,23,22,23,24,23,24,25,24,25,26,26]),
            StockPosition(ticker: "MERD", name: "Meridian Holdings", price: 26.17, shares: 500, field: "Financials", aum: "84B", mcap: "32B", pctChange: -1.12, dayHigh: 26.82, dayLow: 25.91, high52w: 31.44, low52w: 19.80, volume: "8.9M", pe: 10.8, divYield: "4.22%", costBasis: 28.10, sparkData: [18,19,17,16,17,15,16,14,15,13,14,12]),
            StockPosition(ticker: "ORVX", name: "Orvex Logistics", price: 77.90, shares: 66, field: "Industrials", aum: "—", mcap: "24B", pctChange: 0.48, dayHigh: 78.40, dayLow: 76.80, high52w: 84.20, low52w: 58.10, volume: "4.2M", pe: 22.0, divYield: "1.10%", costBasis: 71.22, sparkData: [20,19,21,22,21,22,24,23,24,23,24,25]),
            StockPosition(ticker: "TLRA", name: "Telluran Cloud", price: 231.05, shares: 30, field: "Software", aum: "—", mcap: "148B", pctChange: 2.04, dayHigh: 233.10, dayLow: 225.88, high52w: 248.90, low52w: 168.30, volume: "6.7M", pe: 44.2, divYield: "—", costBasis: 188.50, sparkData: [24,26,25,28,29,28,30,32,31,33,34,36]),
            StockPosition(ticker: "GRYT", name: "Greyton Materials", price: 44.22, shares: 210, field: "Materials", aum: "—", mcap: "16B", pctChange: -0.38, dayHigh: 44.90, dayLow: 43.88, high52w: 52.40, low52w: 33.10, volume: "2.8M", pe: 12.4, divYield: "2.50%", costBasis: 40.80, sparkData: [21,22,21,22,21,20,21,20,19,20,19,19]),
            StockPosition(ticker: "PYRN", name: "Pyron AI", price: 408.77, shares: 12, field: "Software", aum: "—", mcap: "88B", pctChange: 4.12, dayHigh: 410.20, dayLow: 388.10, high52w: 422.88, low52w: 180.00, volume: "14.8M", pe: 82.0, divYield: "—", costBasis: 310.00, sparkData: [16,18,20,22,25,28,30,33,36,40,42,46]),
            StockPosition(ticker: "WSTC", name: "Westcote Foods", price: 62.44, shares: 150, field: "Consumer", aum: "—", mcap: "44B", pctChange: -0.08, dayHigh: 62.80, dayLow: 61.90, high52w: 68.10, low52w: 54.22, volume: "1.9M", pe: 20.1, divYield: "1.88%", costBasis: 60.10, sparkData: [22,22,23,22,22,23,22,22,23,22,22,22]),
            StockPosition(ticker: "DLVR", name: "Delvrex Networks", price: 19.38, shares: 820, field: "Telecom", aum: "—", mcap: "12B", pctChange: 1.22, dayHigh: 19.60, dayLow: 19.02, high52w: 22.40, low52w: 14.10, volume: "9.4M", pe: 16.2, divYield: "5.10%", costBasis: 17.80, sparkData: [14,15,14,16,15,17,16,18,17,19,18,20]),
            StockPosition(ticker: "CNDL", name: "Cendel Biosciences", price: 88.21, shares: 70, field: "Biotech", aum: "—", mcap: "28B", pctChange: 0.96, dayHigh: 89.02, dayLow: 86.44, high52w: 98.10, low52w: 64.20, volume: "3.1M", pe: 38.8, divYield: "—", costBasis: 72.40, sparkData: [18,19,20,19,21,20,22,21,23,22,24,24]),
        ]
    }
}
