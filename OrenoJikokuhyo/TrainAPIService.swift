import Foundation

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

struct RouteItem: Codable {
    let summary: Summary
    let sections: [Section]
}

struct Summary: Codable {
    let move: MoveInfo
}

struct MoveInfo: Codable {
    let time: Int // 所要時間（分）
    let fare: Int // 運賃（円）
}

struct Section: Codable {
    let type: String
    let transport: TransportInfo?
}

struct TransportInfo: Codable {
    let name: String
    let color: String?
}


// MARK: - API通信を行うサービスクラス
// ▲▲▲ ここまでがモデルの定義 ▲▲▲

class TrainAPIService {
    private let rapidAPIHostNodeID = "navitime-transport.p.rapidapi.com"
    private let rapidAPIHostRoute = "navitime-route-totalnavi.p.rapidapi.com"
    private let rapidAPIKey = "8daa388924msh78aa299cdc27584p1f0bfdjsn37fa57fa06e2"
    
    //NodeIDを取得する
    func fetchNodeId(stationName: String) async throws -> String? {
        // 1. URLとクエリパラメータの設定
        var components = URLComponents(string: "https://navitime-transport.p.rapidapi.com/transport_node")!
        components.queryItems = [
            URLQueryItem(name: "name", value: stationName),
            URLQueryItem(name: "type", value: "train"),
            URLQueryItem(name: "limit", value: "1"),
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        // 2. URLRequestの作成とヘッダー情報の設定
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(rapidAPIHostNodeID, forHTTPHeaderField: "x-rapidapi-host")
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
            let nodeIDResponse = try decoder.decode(NodeIDResponse.self, from: data)
            
            // ▼▼▼【変更点2】レスポンス全体ではなく、最初の要素の「id」文字列を返す ▼▼▼
            return nodeIDResponse.items.first?.id
            
        } catch {
            print("Decode Error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw JSON search_station response: \(responseString)")
            }
            throw error
        }
    }
    
    
    // 非同期で経路情報を取得するメソッド
    func fetchRoute(departureNodeID: String, destinationNodeID: String, currentTime: String) async throws -> RouteResponse {
        
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
            return routeResponse
        } catch {
            print("Decode Error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw JSON route_transit response: \(responseString)")
            }
            throw error
        }
    }
}
