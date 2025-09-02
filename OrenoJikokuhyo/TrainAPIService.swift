import Foundation


//
// MARK: - APIレスポンスをデコードするためのCodableモデル
// ▼▼▼【変更点1】すべてのモデルを独立させ、ネストを解消しました ▼▼▼

// transport_node APIのレスポンス用モデル
struct NodeIDResponse: Codable {
    let items: [NodeIDItem]
}

struct NodeIDItem: Codable {
    let id: String
    let name: String
}

// route_transit APIのレスポンス用モデル
struct RouteResponse: Codable {
    let items: [RouteItem]
}

struct Summary: Codable {
    let move: Move
}

struct Move: Codable {
    let fromTime: String // "yyyy-MM-dd'T'HH:mm:ss"

    enum CodingKeys: String, CodingKey {
        case fromTime = "from_time"
    }
}

struct RouteItem: Codable {
    let sections: [Section]
    let summary: Summary
}

struct Section: Codable {
    let type: String
    let transport: TransportInfo?
    let departurePoint: PointInfo?
    let fromTime: String? // "move"セクションの出発時刻

    enum CodingKeys: String, CodingKey {
        case type, transport
        case departurePoint = "departure_point"
        case fromTime = "from_time"
    }
}

struct PointInfo: Codable {
    let time: String // "HH:mm"
    let datetime: String // "yyyy-MM-dd'T'HH:mm:ss"
}

struct TransportInfo: Codable {
    let name: String
    let type: String
    let color: String?
    let links: [LinkInfo]? // linksプロパティを追加
}

// links配列の要素をデコードするためのモデル
struct LinkInfo: Codable {
    let destination: DestinationInfo
}

// destinationオブジェクトをデコードするためのモデル
struct DestinationInfo: Codable {
    let name: String
}


// MARK: - API通信を行うサービスクラス
// ▲▲▲ ここまでがモデルの定義 ▲▲▲

class TrainAPIService {
    private let rapidAPIHostNodeID = "navitime-transport.p.rapidapi.com"
    private let rapidAPIHostRoute = "navitime-route-totalnavi.p.rapidapi.com"
    private let rapidAPIKey = "8daa388924msh78aa299cdc27584p1f0bfdjsn37fa57fa06e2"
    
    // ▼▼▼【新設】駅名検索用のメソッドを追加 ▼▼▼
    func searchStations(query: String) async throws -> [Station] {
        // クエリが空の場合は空の配列を返す
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        
        var components = URLComponents(string: "https://navitime-transport.p.rapidapi.com/transport_node")!
        components.queryItems = [
            URLQueryItem(name: "word", value: query),
            URLQueryItem(name: "type", value: "station"), // "train"よりも"station"の方が広範囲
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(rapidAPIHostNodeID, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            
            throw URLError(.badServerResponse)
        }

        do {
            let decoder = JSONDecoder()
            // 既存のNodeIDResponseモデルを再利用
            let response = try decoder.decode(NodeIDResponse.self, from: data)
            
            // APIレスポンス(NodeIDItem)から、アプリで使うStationモデルの配列に変換して返す
            let stations = response.items.map { Station(name: $0.name, nodeID: $0.id) }
            
            debugPrint("Fetched Stations: \(stations)")
            return stations
            
        } catch {
            print("Decode Error (searchStations): \(error)")
            throw error
        }
    }
    
    // 非同期で経路情報を取得するメソッド
    func fetchRoute(departureNodeID: String, destinationNodeID: String, currentTime: String) async throws -> [Departure] {
        
        // 1. URLとクエリパラメータの設定
        var components = URLComponents(string: "https://navitime-route-totalnavi.p.rapidapi.com/route_transit")!
        components.queryItems = [
            URLQueryItem(name: "start", value: departureNodeID),
            URLQueryItem(name: "goal", value: destinationNodeID),
            URLQueryItem(name: "start_time", value: currentTime),
            URLQueryItem(name: "limit", value: "2"),
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        // 2. URLRequestの作成とヘッダー情報の設定
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(rapidAPIHostRoute, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        
        // 3. URLSessionで通信
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // ステータスコードの確認
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Server error response: \(responseString)")
            }
            throw URLError(.badServerResponse)
        }
        
        // 4. JSONDecoderでデコード
        do {
            let decoder = JSONDecoder()
            let routeResponse = try decoder.decode(RouteResponse.self, from: data)
            // パース処理を呼び出して、[Departure]に変換して返す
            return parseRouteResponse(routeResponse)
        } catch {
            print("Decode Error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw JSON route_transit response: \(responseString)")
            }
            throw error
        }
    }
    
    // RouteResponseから[Departure]への変換ロジック
    private func parseRouteResponse(_ response: RouteResponse) -> [Departure] {
        var departures: [Departure] = []
        let isoDateFormatter = DateFormatter()
        isoDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX" // タイムゾーン(e.g., +09:00)もパースできるように修正
        isoDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoDateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        // APIが返す各経路候補(item)をループ
        for item in response.items {
            // 経路の中から、最初の電車での移動区間(section)を探す
            guard let firstMoveSection = item.sections.first(where: { $0.type == "move" && $0.transport != nil }) else {
                // 電車の移動区間が見つからなければ、この経路候補はスキップ
                continue
            }
            
            // 電車の移動区間から、必須となる情報を取得する
            guard let transport = firstMoveSection.transport, let fromTime = firstMoveSection.fromTime else {
                // 交通情報 or 出発時刻がなければ、この区間はスキップ
                continue
            }

            // 出発時刻をDateオブジェクトに変換する
            guard let departureDate = isoDateFormatter.date(from: fromTime) else {
                // 変換に失敗したらスキップ
                continue
            }
            
            // 補足的な情報を取得する（もし取得できなくても"不明"などで補う）
            let destinationName = transport.links?.first?.destination.name ?? "不明"
            let timeString = timeFormatter.string(from: departureDate)

            // 抽出した情報から、アプリで使うDepartureオブジェクトを作成
            let departure = Departure(
                timeString: timeString,
                departureDate: departureDate,
                line: transport.name,
                trainType: transport.type,
                destination: destinationName
            )
            departures.append(departure)
        }
        
        // 見つかった出発情報を返す（見つからなければ空の配列が返る）
        return departures
    }
}
