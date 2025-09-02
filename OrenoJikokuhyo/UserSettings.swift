//  UserSettings.swift
//  OrenoJikokuhyo

import Foundation

// UserDefaultsを管理するためのクラス。アプリ全体で設定情報を一元管理する
class UserSettings {
    
    
    // UserDefaultsに保存するためのキーを定義
    private enum Keys {
        static let departureName = "departureStationName" // 出発駅の名前
        static let departureNodeID = "departureStationID" // 出発駅のノードID
        static let destinationName = "destinationStationName" // 行き先駅の名前
        static let destinationNodeID = "destinationStationID" // 行き先駅のノードID
    }
    
    // シングルトンインスタンスを提供。アプリ全体で同じ設定情報を共有するため
    static let shared = UserSettings() // シングルトンインスタンス
    private init() {} // 外部からのインスタンス化を禁止
    
    
    // 駅情報をUserDefaultsに保存。
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
    
    // UserDefaultsから駅情報を読み込み。両方の駅情報が揃っている場合にのみStationオブジェクトを返す。
    func loadStations() -> (departure: Station, destination: Station)? {
        let defaults = UserDefaults.standard
        
        
        // UserDefaultsから保存された駅情報を取得
        guard let departureName = defaults.string(forKey: Keys.departureName),
              let departureNodeID = defaults.string(forKey: Keys.departureNodeID),
              let destinationName = defaults.string(forKey: Keys.destinationName),
              let destinationNodeID = defaults.string(forKey: Keys.destinationNodeID)
        else {
            return nil
        }
        
        // 取得した情報を使ってStationオブジェクトを生成して返す
        let departureStation = Station(name: departureName, nodeID: departureNodeID)
        let destinationStation = Station(name: destinationName, nodeID: destinationNodeID)
        
        return (departureStation, destinationStation) // タプルで返す
    }
}
