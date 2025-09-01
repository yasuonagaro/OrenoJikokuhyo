import Foundation


// UserDefaultsを管理するためのクラス
// アプリ全体で設定情報を一元管理する
class UserSettings {


    // UserDefaultsに保存するためのキーを定義します。
    // 文字列を直接書くとタイプミスの原因になるため、定数として管理します。
    private enum Keys {
        static let departureName = "departureStationName"
        static let departureNodeID = "departureStationID"
        static let destinationName = "destinationStationName"
        static let destinationNodeID = "destinationStationID"
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
    
    func saveStations(departure: Station?, destination: Station?) {
        let defaults = UserDefaults.standard

        if let departure = departure {
            // 出発駅の情報を各キーに対応させて保存
            defaults.set(departure.name, forKey: Keys.departureName)
            defaults.set(departure.nodeID, forKey: Keys.departureNodeID)
        } else {
            // データがない場合はキー自体を削除
            defaults.removeObject(forKey: Keys.departureName)
            defaults.removeObject(forKey: Keys.departureNodeID)
        }

        if let destination = destination {
            // 行き先駅の情報を各キーに対応させて保存
            defaults.set(destination.name, forKey: Keys.destinationName)
            defaults.set(destination.nodeID, forKey: Keys.destinationNodeID)
        } else {
            // データがない場合はキー自体を削除
            defaults.removeObject(forKey: Keys.destinationName)
            defaults.removeObject(forKey: Keys.destinationNodeID)
        }
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
        guard let departureName = defaults.string(forKey: Keys.departureName),
              let departureNodeID = defaults.string(forKey: Keys.departureNodeID),
              let destinationName = defaults.string(forKey: Keys.destinationName),
              let destinationNodeID = defaults.string(forKey: Keys.destinationNodeID)
        else {
            return nil
        }

        // 取得した情報から、再度Stationオブジェクトを組み立てて返します。
        let departureStation = Station(name: departureName, nodeID: departureNodeID)
        let destinationStation = Station(name: destinationName, nodeID: destinationNodeID)

        return (departureStation, destinationStation)
    }
}
