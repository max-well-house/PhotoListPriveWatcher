import Foundation

/// Access token source for Sheets REST. Google Sign-In is wired in v0.9.1 on a Mac.
protocol GoogleAuthSession: Sendable {
    func accessToken() async throws -> String
}

/// Placeholder until Sign-In exists. Live `GoogleSheetsClient` throws `notSignedIn`.
struct MissingGoogleAuthSession: GoogleAuthSession {
    func accessToken() async throws -> String {
        throw SheetClientError.notSignedIn
    }
}

/// Local, non-committed Sheet identity. Read from Info.plist keys `SHEET_ID`,
/// `SHEET_ITEMS_TAB`, `SHEET_CONFIG_TAB` — never commit real IDs.
struct SheetsRuntimeConfig: Sendable, Equatable {
    var spreadsheetId: String
    var itemsTab: String
    var configTab: String

    static let spreadsheetsScope = "https://www.googleapis.com/auth/spreadsheets"

    static let itemsHeaders = [
        "id", "photo", "name", "list_owner", "priority", "type", "size", "color", "qty",
        "notes", "status", "stores", "amazon_price", "amazon_url", "target_price",
        "target_url", "walmart_price", "walmart_url", "last_checked", "upc", "asin", "hot",
    ]

    static func fromInfoDictionary(
        _ info: [String: Any]? = Bundle.main.infoDictionary
    ) -> SheetsRuntimeConfig? {
        guard
            let id = info?["SHEET_ID"] as? String
        else { return nil }
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else { return nil }
        let items = (info?["SHEET_ITEMS_TAB"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let config = (info?["SHEET_CONFIG_TAB"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return SheetsRuntimeConfig(
            spreadsheetId: trimmed,
            itemsTab: (items?.isEmpty == false ? items! : "Items"),
            configTab: (config?.isEmpty == false ? config! : "Config")
        )
    }
}

/// Google Sheets API v4 over URLSession. Untested live until v0.9.1 (Mac + Sign-In).
@MainActor
final class GoogleSheetsClient: SheetClient {
    private let auth: any GoogleAuthSession
    private let config: SheetsRuntimeConfig
    private let urlSession: URLSession

    init(
        auth: any GoogleAuthSession,
        config: SheetsRuntimeConfig,
        urlSession: URLSession = .shared
    ) {
        self.auth = auth
        self.config = config
        self.urlSession = urlSession
    }

    func fetchItems() async throws -> [WishlistItem] {
        let rows = try await values(range: "'\(config.itemsTab)'!A2:V")
        var items: [WishlistItem] = []
        for row in rows {
            if let item = Self.item(from: row) {
                items.append(item)
            }
        }
        return items
    }

    func fetchListOwners() async throws -> [String] {
        let rows = try await values(range: "'\(config.configTab)'!A:A")
        var owners: [String] = []
        for (index, row) in rows.enumerated() {
            let cell = Self.cell(row, 0)
            if index == 0, cell.lowercased() == "list_owner" { continue }
            if !cell.isEmpty { owners.append(cell) }
        }
        return owners
    }

    func fetchStores() async throws -> [StoreDirectoryEntry] {
        let rows = try await values(range: "'\(config.configTab)'!C:E")
        var stores: [StoreDirectoryEntry] = []
        for (index, row) in rows.enumerated() {
            let key = Self.cell(row, 0).lowercased()
            if index == 0, key == "store_key" { continue }
            if key.isEmpty { continue }
            let name = Self.cell(row, 1)
            let enabledRaw = Self.cell(row, 2).lowercased()
            let enabled = enabledRaw == "yes" || enabledRaw == "true" || enabledRaw == "1"
            stores.append(
                StoreDirectoryEntry(
                    storeKey: key,
                    displayName: name.isEmpty ? key : name,
                    enabled: enabled
                )
            )
        }
        return stores
    }

    func createTextItem(
        name: String,
        notes: String,
        priority: Int,
        listOwner: String
    ) async throws -> WishlistItem {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw SheetClientError.invalidItem("Name is required.")
        }
        try await requireOwner(listOwner)
        let created = WishlistItem.makeText(
            name: trimmed,
            notes: notes,
            priority: priority,
            listOwner: listOwner
        )
        var row = Array(repeating: "", count: SheetsRuntimeConfig.itemsHeaders.count)
        row[0] = created.id
        row[2] = created.name
        row[3] = created.listOwner
        row[4] = String(created.priority)
        row[5] = created.type
        row[9] = created.notes
        row[10] = created.status
        try await append(row: row)
        return created
    }

    func createTrackedItem(
        name: String,
        notes: String,
        priority: Int,
        listOwner: String,
        storeKeys: [String],
        amazonURL: String?,
        targetURL: String?,
        walmartURL: String?
    ) async throws -> WishlistItem {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw SheetClientError.invalidItem("Name is required.")
        }
        try await requireOwner(listOwner)
        if let message = StoreURL.invalidURLMessage(
            amazonURL: amazonURL,
            targetURL: targetURL,
            walmartURL: walmartURL
        ) {
            throw SheetClientError.invalidItem(message)
        }
        let created = WishlistItem.makeTracked(
            name: trimmed,
            notes: notes,
            priority: priority,
            listOwner: listOwner,
            storeKeys: storeKeys,
            amazonURL: amazonURL,
            targetURL: targetURL,
            walmartURL: walmartURL
        )
        guard created.hasAnyStoreURL, !created.storeKeys.isEmpty else {
            throw SheetClientError.invalidItem("Pick at least one store and paste a product URL.")
        }
        var row = Array(repeating: "", count: SheetsRuntimeConfig.itemsHeaders.count)
        row[0] = created.id
        row[2] = created.name
        row[3] = created.listOwner
        row[4] = String(created.priority)
        row[5] = created.type
        row[9] = created.notes
        row[10] = created.status
        row[11] = created.stores
        row[13] = created.amazonURL ?? ""
        row[15] = created.targetURL ?? ""
        row[17] = created.walmartURL ?? ""
        try await append(row: row)
        return created
    }

    func updateItem(_ item: WishlistItem) async throws {
        try await requireOwner(item.listOwner)
        guard ItemStatus(rawValue: item.status) != nil else {
            throw SheetClientError.invalidItem("Status must be wanted, purchased, or dropped.")
        }
        if let message = StoreURL.invalidURLMessage(
            amazonURL: item.amazonURL,
            targetURL: item.targetURL,
            walmartURL: item.walmartURL
        ) {
            throw SheetClientError.invalidItem(message)
        }
        guard let rowIndex = try await rowIndex(for: item.id) else {
            throw SheetClientError.notFound(item.id)
        }
        let tab = config.itemsTab
        let priority = ItemPriority.clamp(item.priority)
        let type = (item.type == "tracked" || item.hasAnyStoreURL) ? "tracked" : item.type
        let stores = StoreURL.encode(item.storeKeys)
        // D list_owner, E priority, F type, J notes, K status, L stores,
        // N/P/R URLs — never rewrite id or worker-owned prices.
        try await batchUpdate([
            ("'\(tab)'!D\(rowIndex)", item.listOwner),
            ("'\(tab)'!E\(rowIndex)", String(priority)),
            ("'\(tab)'!F\(rowIndex)", type),
            ("'\(tab)'!J\(rowIndex)", item.notes),
            ("'\(tab)'!K\(rowIndex)", item.status),
            ("'\(tab)'!L\(rowIndex)", stores),
            ("'\(tab)'!N\(rowIndex)", item.amazonURL ?? ""),
            ("'\(tab)'!P\(rowIndex)", item.targetURL ?? ""),
            ("'\(tab)'!R\(rowIndex)", item.walmartURL ?? ""),
        ])
    }

    private func requireOwner(_ owner: String) async throws {
        let owners = try await fetchListOwners()
        guard owners.contains(owner) else {
            throw SheetClientError.unknownListOwner(owner)
        }
    }

    private func rowIndex(for itemId: String) async throws -> Int? {
        let rows = try await values(range: "'\(config.itemsTab)'!A2:A")
        for (offset, row) in rows.enumerated() {
            if Self.cell(row, 0) == itemId {
                return offset + 2
            }
        }
        return nil
    }

    private static func item(from row: [String]) -> WishlistItem? {
        let id = cell(row, 0)
        guard !id.isEmpty else { return nil }
        let priorityRaw = cell(row, 4)
        let priority = ItemPriority.clamp(Int(priorityRaw) ?? ItemPriority.default)
        let amazonPrice = cell(row, 12)
        let amazonURL = cell(row, 13)
        let targetPrice = cell(row, 14)
        let targetURL = cell(row, 15)
        let walmartPrice = cell(row, 16)
        let walmartURL = cell(row, 17)
        return WishlistItem(
            id: id,
            name: cell(row, 2),
            listOwner: cell(row, 3).isEmpty ? "Shared" : cell(row, 3),
            priority: priority,
            type: cell(row, 5).isEmpty ? "text" : cell(row, 5),
            notes: cell(row, 9),
            status: cell(row, 10).isEmpty ? ItemStatus.wanted.rawValue : cell(row, 10),
            stores: cell(row, 11),
            amazonPrice: amazonPrice.isEmpty ? nil : amazonPrice,
            amazonURL: amazonURL.isEmpty ? nil : amazonURL,
            targetPrice: targetPrice.isEmpty ? nil : targetPrice,
            targetURL: targetURL.isEmpty ? nil : targetURL,
            walmartPrice: walmartPrice.isEmpty ? nil : walmartPrice,
            walmartURL: walmartURL.isEmpty ? nil : walmartURL
        )
    }

    private static func cell(_ row: [String], _ index: Int) -> String {
        guard index < row.count else { return "" }
        return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func values(range: String) async throws -> [[String]] {
        let encoded = encodeRange(range)
        let url = try sheetsURL("values/\(encoded)")
        let json = try await request(url: url, method: "GET", body: nil)
        if let error = googleError(json) {
            throw SheetClientError.loadFailed(error)
        }
        return stringifyRows(json["values"])
    }

    private func append(row: [String]) async throws {
        let encoded = encodeRange("'\(config.itemsTab)'!A:V")
        var url = try sheetsURL("values/\(encoded):append")
        url = appendQuery(url, [
            "valueInputOption": "USER_ENTERED",
            "insertDataOption": "INSERT_ROWS",
        ])
        let json = try await request(
            url: url,
            method: "POST",
            body: ["values": [row]]
        )
        if let error = googleError(json) {
            throw SheetClientError.saveFailed(error)
        }
    }

    private func batchUpdate(_ cells: [(String, String)]) async throws {
        let url = try sheetsURL("values:batchUpdate")
        let data: [[String: Any]] = cells.map { range, value in
            ["range": range, "values": [[value]]]
        }
        let json = try await request(
            url: url,
            method: "POST",
            body: [
                "valueInputOption": "USER_ENTERED",
                "data": data,
            ]
        )
        if let error = googleError(json) {
            throw SheetClientError.saveFailed(error)
        }
    }

    private func request(url: URL, method: String, body: [String: Any]?) async throws -> [String: Any] {
        let token = try await auth.accessToken()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await urlSession.data(for: request)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
            if http.statusCode == 401 {
                throw SheetClientError.notSignedIn
            }
            throw SheetClientError.saveFailed(
                googleError(json) ?? "Sheets API HTTP \(http.statusCode)"
            )
        }
        if json.isEmpty, !data.isEmpty {
            throw SheetClientError.loadFailed("Sheets API returned unreadable JSON.")
        }
        return json
    }

    private func sheetsURL(_ path: String) throws -> URL {
        let id = config.spreadsheetId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            ?? config.spreadsheetId
        guard let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(id)/\(path)") else {
            throw SheetClientError.loadFailed("Could not build Sheets API URL.")
        }
        return url
    }

    private func encodeRange(_ range: String) -> String {
        range.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? range
    }

    private func appendQuery(_ url: URL, _ pairs: [String: String]) -> URL {
        var parts = URLComponents(url: url, resolvingAgainstBaseURL: false)
        parts?.queryItems = pairs.map { URLQueryItem(name: $0.key, value: $0.value) }
        return parts?.url ?? url
    }

    private func googleError(_ json: [String: Any]) -> String? {
        guard let error = json["error"] as? [String: Any] else { return nil }
        if let message = error["message"] as? String, !message.isEmpty {
            return message
        }
        if let status = error["status"] as? String {
            return status
        }
        return "Sheets API error"
    }

    private func stringifyRows(_ raw: Any?) -> [[String]] {
        guard let rows = raw as? [Any] else { return [] }
        return rows.map { row in
            guard let cells = row as? [Any] else { return [] }
            return cells.map(stringifyCell)
        }
    }

    private func stringifyCell(_ value: Any) -> String {
        if value is NSNull { return "" }
        if let s = value as? String { return s }
        if let n = value as? NSNumber {
            if CFGetTypeID(n) == CFBooleanGetTypeID() {
                return n.boolValue ? "TRUE" : "FALSE"
            }
            if n.doubleValue.rounded() == n.doubleValue {
                return String(n.intValue)
            }
            return String(describing: n)
        }
        return String(describing: value)
    }
}
