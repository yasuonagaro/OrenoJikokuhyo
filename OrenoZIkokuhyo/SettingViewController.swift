import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var departureTextField: UITextField!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    // MainViewControllerから設定されるdelegate
    weak var delegate: SettingsViewControllerDelegate?

    private var allStations = TokyuStationData.stations
    private var filteredStations: [Station] = []

    // どのテキストフィールドが編集中かを保持する
    private var activeTextField: UITextField?

    private var selectedDeparture: Station?
    private var selectedDestination: Station?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        departureTextField.delegate = self
        destinationTextField.delegate = self
        // StoryboardでCellのIdentifierを"StationCell"に設定するのを忘れないように
    }

    // MARK: - Actions
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        guard let departure = selectedDeparture, let destination = selectedDestination else {
            // アラートを表示 (Step 8で実装)
            print("出発駅と行き先駅を選択してください")
            return
        }
        // delegateを通じてMainViewControllerに選択結果を通知
        delegate?.didFinishSetting(departure: departure, destination: destination)
        dismiss(animated: true)
    }

    // MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        filteredStations = allStations
        tableView.reloadData()
    }

    // テキストフィールドの入力が変更されたときに呼ばれる
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        guard let searchText = sender.text, !searchText.isEmpty else {
            filteredStations = allStations
            tableView.reloadData()
            return
        }
        // 駅名に検索テキストが含まれるものをフィルタリング
        filteredStations = allStations.filter { $0.name.contains(searchText) }
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredStations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath)
        cell.textLabel?.text = filteredStations[indexPath.row].name
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

        // 選択後、キーボードとテーブルを非表示にする
        activeTextField?.resignFirstResponder()
        activeTextField = nil
        filteredStations = []
        tableView.reloadData()
    }
}
