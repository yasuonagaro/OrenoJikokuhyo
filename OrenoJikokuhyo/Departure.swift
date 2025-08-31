import Foundation
struct Departure {
    let departureDate: Date // カウントダウン計算用にDate型で保持
    let timeString: String // 表示用の "HH:mm" 形式  <-- この行が必要です
    let destination: String
    let trainType: String
    let line: String
}
