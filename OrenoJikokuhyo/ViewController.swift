//  ViewController.swift

import UIKit

// 設定完了をMainViewControllerに通知するためのプロトコル
protocol SettingsViewControllerDelegate: AnyObject {
    func didFinishSetting(departure: Station?, destination: Station?)
}

// メイン画面のViewController
class ViewController: UIViewController, SettingsViewControllerDelegate {
    
    @IBOutlet weak var currentStationsLabel: UILabel! // 出発駅と到着駅を表示
    @IBOutlet weak var departureTimeLabel: UILabel! // 次の出発時刻を表示
    @IBOutlet weak var countdownLabel: UILabel! // カウントダウンを表示
    @IBOutlet weak var lineDetailLabel: UILabel! // 電車の詳細を表示
    @IBOutlet weak var nextDepartureTimeLabel: UILabel! // 次の出発情報を表示
    @IBOutlet weak var nextCountdownLabel: UILabel! // カウントダウンを表示
    
    private let apiService = TrainAPIService()
    private var departureStation: Station?
    private var destinationStation: Station?
    
    private var departures: [Departure] = []
    private var countdownTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 保存された駅情報を読み込む
        if let stations = UserSettings.shared.loadStations() {
            self.departureStation = stations.departure
            self.destinationStation = stations.destination
        } 
        updateStationLabels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 駅が設定されていれば時刻を再取得
        if departureStation != nil {
            fetchAndDisplayTimetable()
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSettings" { // StoryboardでSegueのIdentifierを設定する
            guard let settingsVC = segue.destination as? SettingsViewController else { return }
            // delegateを設定して、設定完了を自身に通知させる
            settingsVC.delegate = self
            
            // 現在設定されている駅の情報を設定画面に渡す
            settingsVC.initialDeparture = self.departureStation
            settingsVC.initialDestination = self.destinationStation
        }
    }
    
    // SettingsViewControllerDelegateメソッド
    func didFinishSetting(departure: Station?, destination: Station?) {
        self.departureStation = departure
        self.destinationStation = destination
        
        // 新しい設定を保存
        UserSettings.shared.saveStations(departure: departure, destination: destination)
        updateStationLabels()
        // fetchAndDisplayTimetableはviewWillAppearで呼ばれるのでここでは不要
    }
    
    // MARK: - Private Methods
    private func updateStationLabels() {
        if let departure = departureStation, let destination = destinationStation {
            currentStationsLabel.text = "\(departure.name) → \(destination.name)"
        } else {
            // 駅が未設定の場合の表示
            currentStationsLabel.text = "駅を設定してください"
            departureTimeLabel.text = "--:--"
            lineDetailLabel.text = ""
            countdownLabel.text = "--:--"
            nextDepartureTimeLabel.text = "--:--"
            nextCountdownLabel.text = "--:--"
            departures = []
            countdownTimer?.invalidate()
        }
    }
    
    private func fetchAndDisplayTimetable() {
        guard let departure = departureStation else { return }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) // 日曜日=1, 土曜日=7
        var calendarType: String
        if weekday == 1 { calendarType = "odpt.Calendar:Holiday" }
        else if weekday == 7 { calendarType = "odpt.Calendar:Saturday" }
        else { calendarType = "odpt.Calendar:Weekday" }
        
        Task {
            do {
                let timetableObjects = try await apiService.fetchTimetable(
                    stationID: departure.id,
                    directionID: departure.directionID,
                    calendar: calendarType
                )
                self.departures = convertToDepartures(from: timetableObjects)
                // メインスレッドでUI更新
                DispatchQueue.main.async {
                    self.updateDepartureInfo()
                }
            } catch {
                DispatchQueue.main.async {
                    // エラーハンドリング (Step 8で実装)
                    print("API Error: \(error)")
                }
            }
        }
    }
    
    // TimetableObject配列をDeparture配列に変換
    private func convertToDepartures(from objects: [TimetableObject]) -> [Departure] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let now = Date()
        
        let calendar = Calendar.current
        
        return objects.compactMap { obj -> Departure? in
            guard let time = formatter.date(from: obj.departureTime) else { return nil }
            
            var departureDate = calendar.date(bySettingHour: calendar.component(.hour, from: time),
                                              minute: calendar.component(.minute, from: time),
                                              second: 0,
                                              of: now) ?? now
            
            // 深夜帯（例：00:15など）で、現在時刻が23時台の場合、日付を1日進める
            if calendar.component(.hour, from: now) > 22 && calendar.component(.hour, from: departureDate) < 2 {
                departureDate = calendar.date(byAdding: .day, value: 1, to: departureDate) ?? departureDate
            }
            
            if departureDate < now { return nil }
            
            return Departure(
                departureDate: departureDate, timeString: obj.departureTime,
                destination: obj.destinationStation.first?.split(separator: ".").last.map(String.init) ?? "不明",
                trainType: obj.trainType.split(separator: ".").last.map(String.init) ?? "不明",
                line: obj.railway.split(separator: ".").last.map(String.init) ?? "不明"
            )
        }
    }
    
    // 次の出発情報を更新
    private func updateDepartureInfo() {
        guard !departures.isEmpty else {
            departureTimeLabel.text = "--:--"
            lineDetailLabel.text = "本日の運行は終了しました"
            nextDepartureTimeLabel.text = ""
            countdownLabel.text = ""
            countdownTimer?.invalidate() // 終電後はタイマーを止める
            return
        }
        
        let nextDeparture = departures[0]
        departureTimeLabel.text = nextDeparture.timeString
        lineDetailLabel.text = "\(nextDeparture.line) \(nextDeparture.trainType)・\(nextDeparture.destination)方面"
        
        // 次の電車情報
        if departures.count > 1 {
            let secondDeparture = departures[1]
            nextDepartureTimeLabel.text = "次: \(secondDeparture.timeString) | \(secondDeparture.line) \(secondDeparture.trainType)"
        } else {    // 最終電車の場合
            nextDepartureTimeLabel.text = "次の電車はありません"
        }
        
        startCountdown(for: nextDeparture.departureDate)
    }
    
    // カウントダウンタイマーの開始
    private func startCountdown(for date: Date) {
        countdownTimer?.invalidate()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown(targetDate: date)
        }
        // UIの即時反映のため、タイマー開始直後にも一度実行
        updateCountdown(targetDate: date)
    }

    // カウントダウンの更新
    private func updateCountdown(targetDate: Date) {
        let remaining = targetDate.timeIntervalSinceNow
        
        if remaining > 0 {
            let minutes = Int(remaining) / 60
            let seconds = Int(remaining) % 60
            countdownLabel.text = String(format: "あと %02d 分 %02d 秒", minutes, seconds) // "あと mm 分 ss 秒" 形式で表示
        } else {
            countdownLabel.text = "発車しました"
            countdownTimer?.invalidate()
            countdownTimer = nil
            
            // 1秒後に時刻表を再取得
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.fetchAndDisplayTimetable()
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
