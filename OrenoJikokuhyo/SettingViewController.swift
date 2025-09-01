//
//  SettingsViewController.swift
//  OrenoJikokuhyo
//

import UIKit
import GoogleMobileAds

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var departureTextField: UITextField!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bannerView: BannerView!

    // MARK: - Public Properties
    var departure: Station?
    var destination: Station?
    weak var delegate: SettingsViewControllerDelegate?

    // MARK: - Private Properties
    private let apiService = TrainAPIService()
    private var searchResults: [Station] = []
    private var searchTimer: Timer?
    private var activeTextField: UITextField?
    private var selectedDeparture: Station?
    private var selectedDestination: Station?

    private var adManager: AdManager?
    private let adUnitID = "ca-app-pub-2578365445147845/7568523231" // 設定画面用の広告ユニットID

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialData()
        setupAd()
    }

    // MARK: - Setup
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

    private func loadInitialData() {
        selectedDeparture = departure
        selectedDestination = destination
        departureTextField.text = departure?.name
        destinationTextField.text = destination?.name
    }
    
    private func setupAd() {
        adManager = AdManager()
        adManager?.startGoogleMobileAdsSDK(bannerView: bannerView, rootViewController: self, in: self.view, adUnitID: adUnitID)
    }

    // MARK: - Actions
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
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
    
    // MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        tableView.isHidden = false
        updateTableViewHeight()
        // 編集開始時に即座に検索を実行
        textFieldDidChange(textField)
    }

    // MARK: - Search Logic
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

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath)
        let station = searchResults[indexPath.row]
        
        cell.backgroundColor = UIColor(red: 0.12, green: 0.16, blue: 0.27, alpha: 1.0)
        cell.textLabel?.text = station.name
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        return cell
    }

    // MARK: - UITableViewDelegate
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

    // MARK: - Helper Methods
    private func resetStationSelectionAndList(for textField: UITextField) {
        if textField == departureTextField {
            selectedDeparture = nil
        } else if textField == destinationTextField {
            selectedDestination = nil
        }
        clearAndHideTableView()
    }

    private func clearAndHideTableView() {
        searchResults = []
        tableView.reloadData()
        tableView.isHidden = true
    }
    
    private func updateTableViewHeight() {
        let contentHeight = tableView.contentSize.height
        let maxHeight: CGFloat = 300 // テーブルビューの最大の高さを設定
        tableViewHeightConstraint.constant = min(contentHeight, maxHeight)
    }
    
    private func setTextFieldPlaceholderColor(textField: UITextField, color: UIColor) {
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: color]
            )
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
