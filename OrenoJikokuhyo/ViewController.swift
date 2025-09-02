//  ViewController.swift
//  OrenoJikokuhyo

import GoogleMobileAds
import UIKit

// 設定完了をMainViewControllerに通知するためのプロトコル
protocol SettingsViewControllerDelegate: AnyObject {
    func didFinishSetting(departure: Station?, destination: Station?)
}

// メイン画面のViewController
class ViewController: UIViewController, SettingsViewControllerDelegate, BannerViewDelegate {
    
    @IBOutlet weak var currentStationsLabel: UILabel! // 出発駅と到着駅を表示
    @IBOutlet weak var departureTimeLabel: UILabel! // 次の出発時刻を表示
    @IBOutlet weak var countdownLabel: UILabel! // カウントダウンを表示
    @IBOutlet weak var lineDetailLabel: UILabel! // 電車の詳細を表示
    @IBOutlet weak var nextDepartureTimeLabel: UILabel! // 次の出発情報を表示
    @IBOutlet weak var nextCountdownLabel: UILabel! // カウントダウンを表示
    @IBOutlet weak var bannerView: BannerView! // バナー広告表示用のビュー
    
    private let apiService = TrainAPIService() // APIサービスのインスタンス
    private var departure: Station? // 出発駅
    private var destination: Station? // 到着駅
    private var departures: [Departure] = [] // 出発情報の配列
    
    private var countdownTimer: Timer? // カウントダウンタイマー
    
    private var adManager: AdManager? // AdMob用のインスタンス
    private let adUnitID = "ca-app-pub-2578365445147845/9108550209" // メイン画面用広告ユニットID（本番用）はca-app-pub-2578365445147845/9108550209
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 保存された駅情報を読み込む
        if let stations = UserSettings.shared.loadStations() {
            
            self.departure = stations.departure
            self.destination = stations.destination
        }
        
        updateStationLabels() // 駅ラベルの更新
        
        // AdManagerの初期化
        adManager = AdManager()
        
        // バナー広告の読み込み
        adManager?.startGoogleMobileAdsSDK(bannerView: bannerView, rootViewController: self, in: self.view, adUnitID: adUnitID)
    }
    
    // 画面が表示される直前に呼ばれる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 駅が設定されていれば時刻を再取得
        if departure != nil {
            fetchAndDisplayRoute()
        }
    }
    
    // Segueの準備
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSettings" { // StoryboardでSegueのIdentifierを設定する
            guard let settingsVC = segue.destination as? SettingsViewController else { return }
            // delegateを設定して、設定完了を自身に通知させる
            settingsVC.delegate = self
            
            // 現在設定されている駅の情報を設定画面に渡す
            settingsVC.departure = self.departure
            settingsVC.destination = self.destination
        }
    }
    
    // SettingsViewControllerDelegateメソッド
    func didFinishSetting(departure: Station?, destination: Station?) {
        self.departure = departure
        self.destination = destination
        
        // 新しい設定を保存
        UserSettings.shared.saveStations(departure: departure, destination: destination)
        updateStationLabels()
        
        // 新しい駅が設定されたので、すぐに経路を再検索する
        if departure != nil {
            fetchAndDisplayRoute()
        }
    }
    
    // 駅設定に基づいて時刻表を取得して表示を更新
    private func updateStationLabels() {
        if let departure = departure, let destination = destination {   // 駅が設定されている場合
            currentStationsLabel.text = "\(departure.name) → \(destination.name)" // 駅名を表示
        } else { // 駅が未設定の場合の表示
            currentStationsLabel.text = "駅を設定してください" // 駅名を表示
            departureTimeLabel.text = "--:--" // 出発時刻をクリア
            lineDetailLabel.text = "" // 詳細情報もクリア
            countdownLabel.text = "--:--" // カウントダウンもクリア
            nextDepartureTimeLabel.text = "--:--"  // 次の電車の表示もクリア
            nextCountdownLabel.text = "--:--" // 次の電車のカウントダウンもクリア
            departures = [] // 出発情報をクリア
            countdownTimer?.invalidate()
        }
    }
    
    // 駅設定に基づいて経路を取得し、表示を更新
    private func fetchAndDisplayRoute() {
        let dateFormatter = DateFormatter() // API用の日時フォーマット
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // APIが要求するフォーマット
        let currentTime = Date() // 現在日時
        let currentTimeString = dateFormatter.string(from: currentTime) // フォーマットされた現在日時文字列
        
        guard let departure = departure else { return } // 出発駅が設定されていない場合は何もしない
        print("Fetching route for \(departure.name)...") // デバッグ出力
        
        // 非同期タスクとしてAPIを呼び出す
        Task {
            do {
                let routeObjects = try await apiService.fetchRoute(departureNodeID: departure.nodeID, destinationNodeID: destination?.nodeID ?? "", currentTime: currentTimeString
                )
                
                self.departures = routeObjects
                
                print("Successfully fetched \(self.departures.count) departures.") // デバッグ出力
                
                // メインスレッドでUI更新
                DispatchQueue.main.async {
                    self.updateResult()
                }
            } catch {
                DispatchQueue.main.async {
                    // エラーハンドリング
                    print("API Error in fetchAndDisplayRoute: \(error)") // デバッグ出力
                }
            }
        }
    }
    
    // 次の出発情報を更新
    private func updateResult() {
        // 1番目の出発情報
        guard !departures.isEmpty else { // 出発情報がない場合
            departureTimeLabel.text = "--:--"
            lineDetailLabel.text = "本日の運行は終了しました"
            countdownLabel.text = ""
            nextDepartureTimeLabel.text = ""
            nextCountdownLabel.text = ""
            countdownTimer?.invalidate() // 終電後はタイマーを止める
            return
        }
        
        let nextDeparture = departures[0] // 1番目の出発情報
        departureTimeLabel.text = nextDeparture.timeString // "10:30"のような表示
        lineDetailLabel.text = "\(nextDeparture.line) \(nextDeparture.trainType)" // 路線名と種別
        
        // 2番目の出発情報
        if departures.count > 1 { // 2番目が存在する場合
            let secondDeparture = departures[1] // 2番目の出発情報
            nextDepartureTimeLabel.text = "\(secondDeparture.timeString) | \(secondDeparture.line) \(secondDeparture.trainType)" // "10:45 | JR山手線 普通"のような表示
        } else {    // 最終電車の場合
            nextDepartureTimeLabel.text = "次の電車はありません" // 2番目がない場合の表示
            nextCountdownLabel.text = "" // 2番目がない場合はカウントダウンも消す
        }
        
        // カウントダウンタイマーを開始または更新
        startOrUpdateCountdownTimer()
    }
    
    // カウントダウンタイマーを開始または更新する
    private func startOrUpdateCountdownTimer() {
        countdownTimer?.invalidate() // 既存のタイマーを停止
        
        // 表示すべき出発情報がなければ何もしない
        guard !departures.isEmpty else { return }
        
        // 1秒ごとにupdateCountdownsを呼び出すタイマーを開始
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdowns), userInfo: nil, repeats: true)
    }
    
    // カウントダウン表示を更新する（タイマーから1秒ごとに呼ばれる）
    @objc private func updateCountdowns() {
        var shouldRefresh = false
        
        // 1番目のカウントダウン
        if !departures.isEmpty { // 出発情報がある場合
            let targetDate = departures[0].departureDate
            let remaining = targetDate.timeIntervalSinceNow
            
            if remaining > 0 { // 発車時刻までの時間がある場合
                let minutes = Int(remaining) / 60 // 分
                let seconds = Int(remaining) % 60 // 秒
                countdownLabel.text = String(format: "%02d 分 %02d 秒", minutes, seconds) // "05 分 30 秒"のような表示
            } else {
                // 発車時刻を過ぎたらリフレッシュフラグを立てる
                if countdownLabel.text != "発車しました" {
                    shouldRefresh = true // 一度だけフラグを立てる
                }
                countdownLabel.text = "発車しました" // 発車済みの表示
            }
        }
        
        // 2番目のカウントダウン
        if departures.count > 1 {
            let targetDate = departures[1].departureDate // 2番目の出発時刻
            let remaining = targetDate.timeIntervalSinceNow // 残り時間
            
            if remaining > 0 { // 発車時刻までの時間がある場合
                let minutes = Int(remaining) / 60 // 分
                let seconds = Int(remaining) % 60
                nextCountdownLabel.text = String(format: "%02d 分 %02d 秒", minutes, seconds) // "05 分 30 秒"のような表示
            } else {
                nextCountdownLabel.text = "発車しました" } // 発車済みの表示
        } else {
            nextCountdownLabel.text = "" // 2番目がない場合は空にする
        }
        
        // 最初の電車が発車したら、1秒後に時刻表を再取得
        if shouldRefresh {
            countdownTimer?.invalidate() // タイマーを一旦止める
            countdownTimer = nil // 解放
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.fetchAndDisplayRoute() // 1秒後に再取得
            }
        }
    }
    
    // 画面が非表示になる際にタイマーを止める
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}
