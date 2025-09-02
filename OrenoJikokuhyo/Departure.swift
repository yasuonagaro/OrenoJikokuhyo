//  Departure.swift
//  OrenoJikokuhyo

import Foundation

// 電車の出発情報を表す構造体
struct Departure {
    let timeString: String      // "10:30"のような表示用の時刻
    let departureDate: Date     // カウントダウン用のDateオブジェクト
    let line: String            // 路線名 (例: "JR山手線")
    let trainType: String       // 種別 (例: "普通")
    let destination: String     // 行き先 (例: "新宿")
}
