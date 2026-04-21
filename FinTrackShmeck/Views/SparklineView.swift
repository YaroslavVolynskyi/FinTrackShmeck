import SwiftUI

struct SparklineView: View {
    let data: [Double]
    let isPositive: Bool
    let theme: AppTheme

    private let width: CGFloat = 56
    private let height: CGFloat = 18

    var body: some View {
        Canvas { context, size in
            guard data.count > 1 else { return }
            let minVal = data.min() ?? 0
            let maxVal = data.max() ?? 1
            let span = max(1, maxVal - minVal)

            var path = Path()
            for (index, value) in data.enumerated() {
                let x = CGFloat(index) / CGFloat(data.count - 1) * (size.width - 2) + 1
                let y = size.height - 2 - ((value - minVal) / span) * (size.height - 4)
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            let color = isPositive ? theme.positive : theme.negative
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
        }
        .frame(width: width, height: height)
    }
}
