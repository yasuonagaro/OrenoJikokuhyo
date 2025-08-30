import Foundation

class TrainAPIService {
    private let accessToken = "アクセストークン" // ここに実際のアクセストークンを入れる


    func fetchTimetable(stationID: String, directionID: String, calendar: String) async throws -> [TimetableObject] {
        var components = URLComponents(string: "[https://api.odpt.org/api/v4/odpt:StationTimetable](https://api.odpt.org/api/v4/odpt:StationTimetable)")!
        components.queryItems = [
            URLQueryItem(name: "acl:consumerKey", value: accessToken),
            URLQueryItem(name: "odpt:station", value: stationID),
            URLQueryItem(name: "odpt:railDirection", value: directionID),
            URLQueryItem(name: "odpt:calendar", value: calendar)
        ]


        guard let url = components.url else {
            // 本来はカスタムエラーを定義するのが望ましい
            throw URLError(.badURL)
        }


        // URLSessionで通信
        let (data, response) = try await URLSession.shared.data(from: url)


        // ステータスコードの確認
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }


        // JSONDecoderでデコード
        let decoder = JSONDecoder()
        let timetableResponse = try decoder.decode([StationTimetable].self, from: data)


        // APIの仕様上、結果は通常1つの要素を持つ配列で返ってくる
        return timetableResponse.first?.stationTimetableObject ?? []
    }
}
