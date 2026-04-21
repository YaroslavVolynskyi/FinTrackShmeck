import SwiftUI

struct BlinkModifier: ViewModifier {
    let alertInfo: Bool?  // nil = no alert, true = buy (green), false = sell (red)
    let positiveColor: Color
    let negativeColor: Color

    @State private var blinkOn = false
    @State private var blinkCount = 0
    @State private var timer: Timer?

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if alertInfo != nil && blinkOn {
                        (alertInfo == true ? positiveColor : negativeColor)
                            .opacity(0.3)
                    }
                }
            )
            .onChange(of: alertInfo != nil) { _, isActive in
                if isActive {
                    startBlinking()
                } else {
                    stopBlinking()
                }
            }
            .onAppear {
                if alertInfo != nil {
                    startBlinking()
                }
            }
    }

    private func startBlinking() {
        blinkCount = 0
        blinkOn = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { t in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    blinkOn.toggle()
                }
                if !blinkOn {
                    blinkCount += 1
                }
                if blinkCount >= 5 {
                    t.invalidate()
                    blinkOn = false
                }
            }
        }
    }

    private func stopBlinking() {
        timer?.invalidate()
        timer = nil
        blinkOn = false
        blinkCount = 0
    }
}
