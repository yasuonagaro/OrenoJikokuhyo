// Timetable.swift - APIレスポンスを直接マッピングするためのモデル

struct StationTimetable: Codable { // 駅の時刻表全体を表す構造体
    let stationTimetableObject: [TimetableObject]

    enum CodingKeys: String, CodingKey {
        case stationTimetableObject = "odpt:stationTimetableObject"
    }
}

struct TimetableObject: Codable { // 個々の時刻表エントリを表す構造体
    let departureTime: String
    let destinationStation: [String]
    let trainType: String
    let railway: String

    enum CodingKeys: String, CodingKey {
        case departureTime = "odpt:departureTime"
        case destinationStation = "odpt:destinationStation"
        case trainType = "odpt:trainType"
        case railway = "odpt:railway"
    }
}
