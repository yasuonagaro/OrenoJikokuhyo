import UIKit
import GoogleMobileAds

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var departureTextField: UITextField!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bannerView: BannerView! // バナー広告表示用のビュー

    // ViewControllerから渡される現在の設定
    var departure: Station?
    var destination: Station?
    
    // MainViewControllerから設定されるdelegate
    weak var delegate: SettingsViewControllerDelegate?
    
    // アプリに保存されている全駅リスト
    private var filteredStations: [Station] = []

    // どのテキストフィールドが編集中かを保持する
    private var activeTextField: UITextField?

    // この画面で選択された駅
    private var selectedDeparture: Station?
    private var selectedDestination: Station?
    
    private var adManager: AdManager?
    private let adUnitID = "ca-app-pub-2578365445147845/7568523231" // 設定画面用広告ユニットID（本番用）はca-app-pub-2578365445147845/7568523231

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        departureTextField.delegate = self
        destinationTextField.delegate = self
        
        // 初期状態ではテーブルビューを非表示にする
        tableView.isHidden = true
        
        // ViewControllerから渡された値を設定
        selectedDeparture = departure
        selectedDestination = destination
        
        departureTextField.text = departure?.name
        destinationTextField.text = destination?.name
        
        // プレースホルダーの色を設定
        let placeholderColor = UIColor(white: 0.667, alpha: 1.0)
        
        if let departurePlaceholder = departureTextField.placeholder {
            departureTextField.attributedPlaceholder = NSAttributedString(
                string: departurePlaceholder,
                attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
            )
        }
        
        if let destinationPlaceholder = destinationTextField.placeholder {
            destinationTextField.attributedPlaceholder = NSAttributedString(
                string: destinationPlaceholder,
                attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
            )
        }
        
        // AdManagerの初期化
        adManager = AdManager()

        // バナー広告の読み込み
        adManager?.startGoogleMobileAdsSDK(bannerView: bannerView, rootViewController: self, in: self.view, adUnitID: adUnitID)
    }

    // MARK: - Actions
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        // Case 1: Both stations are set
        if let departure = selectedDeparture, let destination = selectedDestination {
            // Check if they are the same station
            if departure.nodeID == destination.nodeID {
                let alert = UIAlertController(title: "入力エラー", message: "出発駅と到着駅には同じ駅を設定できません。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            // If they are different, proceed to save
            delegate?.didFinishSetting(departure: departure, destination: destination)
            dismiss(animated: true)

        // Case 2: Both stations are NOT set (i.e., they are nil)
        } else if selectedDeparture == nil && selectedDestination == nil {
            // This is a valid "reset" state, proceed to save
            delegate?.didFinishSetting(departure: nil, destination: nil)
            dismiss(animated: true)

        // Case 3: Only one of the two is set (invalid state)
        } else {
            let alert = UIAlertController(title: "入力エラー", message: "出発駅と到着駅を両方とも設定するか、両方とも空にしてください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        // 編集開始時にリストを更新して表示
        refreshStationList(for: textField)
    }

    @IBAction func textFieldDidChange(_ sender: UITextField) {
        // テキストが空になったら、対応する駅の選択を解除
        if sender.text?.isEmpty ?? true {
            if sender == departureTextField {
                selectedDeparture = nil
            } else if sender == destinationTextField {
                selectedDestination = nil
            }
        }
        // 入力のたびにリストを更新
        refreshStationList(for: sender)
    }
    
    // 駅の検索結果リストを更新・表示するヘルパーメソッド
    private func refreshStationList(for textField: UITextField) {
        let searchText = textField.text ?? ""
        
        // UI更新
        tableView.isHidden = false
        tableView.reloadData()
        DispatchQueue.main.async {
            self.updateTableViewHeight()
        }
    }
    
    private func updateTableViewHeight() {
        // contentSizeの高さに基づいて制約を更新
        let contentHeight = tableView.contentSize.height
        let maxHeight: CGFloat = 300 // テーブルビューの最大の高さ
        
        tableViewHeightConstraint.constant = min(contentHeight, maxHeight)
    }


    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredStations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath)
        let station = filteredStations[indexPath.row]
        
        // セルの背景色を設定
        cell.backgroundColor = UIColor(red: 0.12, green: 0.16, blue: 0.27, alpha: 1.0)

        // テキストラベルの設定
        cell.textLabel?.text = station.name
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)

        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedStation = filteredStations[indexPath.row]

        if activeTextField == departureTextField {
            departureTextField.text = selectedStation.name
            selectedDeparture = selectedStation
        } else if activeTextField == destinationTextField {
            destinationTextField.text = selectedStation.name
            selectedDestination = selectedStation
        }

        // 選択後、キーボードを閉じてテーブルを非表示にする
        activeTextField?.resignFirstResponder()
        activeTextField = nil
        
        tableView.isHidden = true
        filteredStations = []
        tableView.reloadData()
    }
}
