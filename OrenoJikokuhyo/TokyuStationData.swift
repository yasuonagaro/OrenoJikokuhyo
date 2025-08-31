struct TokyuStationData {
    static let stations: [Station] = [
        Station(name: "渋谷", id: "odpt.Station:Tokyu.Toyoko.Shibuya", directionID: "odpt.RailDirection:Tokyu.Yokohama"),
        Station(name: "中目黒", id: "odpt.Station:Tokyu.Toyoko.NakaMeguro", directionID: "odpt.RailDirection:Tokyu.Yokohama"),
        // ... 他の東急線の駅をすべて定義 ...
    ]
}
