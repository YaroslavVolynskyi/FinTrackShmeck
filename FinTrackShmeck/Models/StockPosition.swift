import Foundation

struct StockPosition: Identifiable {
    let id: UUID
    var ticker: String
    var name: String
    var price: Double
    var shares: Int
    var field: String
    var aum: String
    var mcap: String
    var pctChange: Double
    var dayHigh: Double
    var dayLow: Double
    var high52w: Double
    var low52w: Double
    var volume: String
    var pe: Double
    var divYield: String
    var costBasis: Double
    var sparkData: [Double]

    init(
        ticker: String = "", name: String = "", price: Double = 0, shares: Int = 0,
        field: String = "", aum: String = "—", mcap: String = "—", pctChange: Double = 0,
        dayHigh: Double = 0, dayLow: Double = 0, high52w: Double = 0, low52w: Double = 0,
        volume: String = "—", pe: Double = 0, divYield: String = "—", costBasis: Double = 0,
        sparkData: [Double] = [20,20,20,20,20,20,20,20,20,20,20,20]
    ) {
        self.id = UUID()
        self.ticker = ticker
        self.name = name
        self.price = price
        self.shares = shares
        self.field = field
        self.aum = aum
        self.mcap = mcap
        self.pctChange = pctChange
        self.dayHigh = dayHigh
        self.dayLow = dayLow
        self.high52w = high52w
        self.low52w = low52w
        self.volume = volume
        self.pe = pe
        self.divYield = divYield
        self.costBasis = costBasis
        self.sparkData = sparkData
    }
}
