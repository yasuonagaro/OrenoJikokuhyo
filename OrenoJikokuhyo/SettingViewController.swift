//  SettingsViewController.swift
//  OrenoJikokuhyo

import UIKit
import GoogleMobileAds

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var departureTextField: UITextField! // 出発駅入力用テキストフィールド
    @IBOutlet weak var destinationTextField: UITextField! // 到着駅入力用テキストフィールド
    @IBOutlet weak var tableView: UITableView! // 駅候補表示用テーブルビュー
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!   // テーブルビューの高さ制約
    @IBOutlet weak var bannerView: BannerView! // バナー広告表示用のビュー
    
    
    var departure: Station? // 既に設定されている出発駅
    var destination: Station? // 既に設定されている到着駅
    weak var delegate: SettingsViewControllerDelegate? // 設定完了を通知するデリゲート
    
    private let apiService = TrainAPIService() // APIサービスのインスタンス
    private var searchResults: [Station] = [] // 駅検索結果の配列
    private var searchTimer: Timer? // 検索デバウンスタイマー
    private var activeTextField: UITextField? // 現在編集中のテキストフィールド
    private var selectedDeparture: Station? // 選択された出発駅
    private var selectedDestination: Station? // 選択された到着駅
    
    private var adManager: AdManager? // AdMob用のインスタンス
    private let adUnitID = "ca-app-pub-2578365445147845/7568523231" // 設定画面用の広告ユニットID
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialData()
        setupAd()
    }
    
    // 設定画面の初期化
    private func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        departureTextField.delegate = self
        destinationTextField.delegate = self
        tableView.isHidden = true
        
        let placeholderColor = UIColor(white: 0.667, alpha: 1.0)
        setTextFieldPlaceholderColor(textField: departureTextField, color: placeholderColor)
        setTextFieldPlaceholderColor(textField: destinationTextField, color: placeholderColor)
    }
    
    // 初期データの読み込み
    private func loadInitialData() {
        selectedDeparture = departure
        selectedDestination = destination
        departureTextField.text = departure?.name
        destinationTextField.text = destination?.name
    }
    
    //AdMobのセットアップ
    private func setupAd() {
        adManager = AdManager()
        adManager?.startGoogleMobileAdsSDK(bannerView: bannerView, rootViewController: self, in: self.view, adUnitID: adUnitID)
    }
    
    // キャンセルボタンと完了ボタンのアクション
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    // 完了ボタンのアクション
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        // 出発駅と到着駅が同じ場合はエラー
        if let departure = selectedDeparture, let destination = selectedDestination, departure.nodeID == destination.nodeID {
            showAlert(title: "入力エラー", message: "出発駅と到着駅には同じ駅を設定できません。")
            return
        }
        
        // 両方設定されているか、両方空の場合のみ delegate を呼ぶ
        if (selectedDeparture != nil && selectedDestination != nil) || (selectedDeparture == nil && selectedDestination == nil) {
            delegate?.didFinishSetting(departure: selectedDeparture, destination: selectedDestination)
            dismiss(animated: true)
        } else {
            showAlert(title: "入力エラー", message: "出発駅と到着駅を両方とも設定するか、両方とも空にしてください。")
        }
    }
    
    // テキストフィールドの内容が変更されたときのアクション
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        // 既存のタイマーを無効化
        searchTimer?.invalidate()
        
        // テキストが空なら検索結果をクリアして非表示にする
        guard let searchText = sender.text, !searchText.isEmpty else {
            resetStationSelectionAndList(for: sender)
            return
        }
        
        // 0.3秒の遅延（デバウンス）を設けてAPIを呼び出す
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { [weak self] _ in
            self?.performSearch(query: searchText)
        })
    }
    
    // UITextFieldDelegateメソッド
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        tableView.isHidden = false
        updateTableViewHeight()
        // 編集開始時に即座に検索を実行
        textFieldDidChange(textField)
    }
    
    // テキストフィールドの編集が終了したときのアクション
    private func performSearch(query: String) {
        // 非同期タスクとしてAPIを呼び出す
        Task {
            do {
                let stations = try await apiService.searchStations(query: query)
                
                // メインスreadでUIを更新
                DispatchQueue.main.async {
                    self.handleSearchResult(stations: stations)
                }
            } catch {
                print("駅の検索に失敗しました: \(error)")
                // エラー発生時はリストをクリア
                DispatchQueue.main.async {
                    self.clearAndHideTableView()
                }
            }
        }
    }
    
    // 検索結果を処理してテーブルビューを更新
    private func handleSearchResult(stations: [Station]) {
        // 反対側に設定済みの駅は候補から除外する
        let stationToExclude = (self.activeTextField == self.departureTextField) ? self.selectedDestination : self.selectedDeparture
        
        if let excludeStation = stationToExclude {
            self.searchResults = stations.filter { $0.nodeID != excludeStation.nodeID }
        } else {
            self.searchResults = stations
        }
        
        self.tableView.reloadData()
        self.updateTableViewHeight()
        self.tableView.isHidden = self.searchResults.isEmpty
    }
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath)
        let station = searchResults[indexPath.row]
        
        cell.backgroundColor = UIColor(red: 0.12, green: 0.16, blue: 0.27, alpha: 1.0)
        cell.textLabel?.text = station.name
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        return cell
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedStation = searchResults[indexPath.row]
        
        if activeTextField == departureTextField {
            departureTextField.text = selectedStation.name
            selectedDeparture = selectedStation
        } else if activeTextField == destinationTextField {
            destinationTextField.text = selectedStation.name
            selectedDestination = selectedStation
        }
        
        activeTextField?.resignFirstResponder()
        activeTextField = nil
        
        clearAndHideTableView()
    }
    
    // 駅選択とリストのリセット
    private func resetStationSelectionAndList(for textField: UITextField) {
        if textField == departureTextField {
            selectedDeparture = nil
        } else if textField == destinationTextField {
            selectedDestination = nil
        }
        clearAndHideTableView()
    }
    
    // テーブルビューをクリアして非表示にする
    private func clearAndHideTableView() {
        searchResults = []
        tableView.reloadData()
        tableView.isHidden = true
    }
    
    // テーブルビューの高さを内容に応じて調整
    private func updateTableViewHeight() {
        let contentHeight = tableView.contentSize.height
        let maxHeight: CGFloat = 220 // テーブルビューの最大の高さを設定
        tableViewHeightConstraint.constant = min(contentHeight, maxHeight)
    }
    
    // プレースホルダーの色を設定
    private func setTextFieldPlaceholderColor(textField: UITextField, color: UIColor) {
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: color]
            )
        }
    }
    
    // アラートを表示するヘルパーメソッド
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
