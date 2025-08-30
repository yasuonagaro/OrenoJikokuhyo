import Foundation


// UserDefaultsを管理するためのクラス
// アプリ全体で設定情報を一元管理する
class UserSettings {


    // UserDefaultsに保存するためのキーを定義します。
    // 文字列を直接書くとタイプミスの原因になるため、定数として管理します。
    private enum Keys {
        static let departureStationName = "departureStationName"
        static let departureStationID = "departureStationID"
        static let departureStationDirectionID = "departureStationDirectionID"


        static let destinationStationName = "destinationStationName"
        static let destinationStationID = "destinationStationID"
        static let destinationStationDirectionID = "destinationStationDirectionID"
    }


    // アプリ内で常に同じインスタンスを使えるようにシングルトンパターンにします。
    static let shared = UserSettings()
    private init() {} // 外部からのインスタンス化を禁止


    /**
     出発駅と行き先駅の情報をUserDefaultsに保存します。
     - Parameters:
       - departure: 保存する出発駅のStationオブジェクト
       - destination: 保存する行き先駅のStationオブジェクト
     */
    
    // Station構造体はStation.swiftに定義されている前提
    func saveStations(departure: Station, destination: Station) {
        let defaults = UserDefaults.standard


        // 出発駅の情報を各キーに対応させて保存
        defaults.set(departure.name, forKey: Keys.departureStationName)
        defaults.set(departure.id, forKey: Keys.departureStationID)
        defaults.set(departure.directionID, forKey: Keys.departureStationDirectionID)


        // 行き先駅の情報を各キーに対応させて保存
        defaults.set(destination.name, forKey: Keys.destinationStationName)
        defaults.set(destination.id, forKey: Keys.destinationStationID)
        defaults.set(destination.directionID, forKey: Keys.destinationStationDirectionID)
    }


    /**
     UserDefaultsから駅設定を読み込みます。
     - Returns: 保存されていた出発駅と行き先駅のタプル。データがない場合はnilを返します。
     */
    
    // Station構造体はStation.swiftに定義されている前提
    func loadStations() -> (departure: Station, destination: Station)? {
        let defaults = UserDefaults.standard


        // 各キーを使って情報を取得します。
        // 必要な情報が一つでも欠けている場合（初回起動時など）は、nilを返して処理を中断します。
        guard let departureName = defaults.string(forKey: Keys.departureStationName),
              let departureID = defaults.string(forKey: Keys.departureStationID),
              let departureDirectionID = defaults.string(forKey: Keys.departureStationDirectionID),
              let destinationName = defaults.string(forKey: Keys.destinationStationName),
              let destinationID = defaults.string(forKey: Keys.destinationStationID),
              let destinationDirectionID = defaults.string(forKey: Keys.destinationStationDirectionID) else {
            return nil
        }


        // 取得した情報から、再度Stationオブジェクトを組み立てて返します。
        let departureStation = Station(name: departureName, id: departureID, directionID: departureDirectionID)
        let destinationStation = Station(name: destinationName, id: destinationID, directionID: destinationDirectionID)


        return (departureStation, destinationStation)
    }
}
