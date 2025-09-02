//  Station.swift
//  OrenoJikokuhyo

// Station.swift - アプリに保存する駅情報のモデル
struct Station: Codable, Hashable {
    let name: String
    let nodeID: String
}
