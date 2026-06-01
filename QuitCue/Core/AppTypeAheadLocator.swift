import Foundation

protocol AppTypeAheadLocatable {
    var bundleID: String { get }
    var name: String { get }
}

extension InstalledApp: AppTypeAheadLocatable {}

struct AppTypeAheadLocator {
    let timeout: TimeInterval

    private var query = ""
    private var lastTypedAt: Date?

    init(timeout: TimeInterval = 0.8) {
        self.timeout = timeout
    }

    mutating func locate<Item: AppTypeAheadLocatable>(
        typedCharacter: String,
        in items: [Item],
        currentBundleID: String?,
        now: Date = Date()
    ) -> Item? {
        guard let character = typedCharacter.first else { return nil }

        if let lastTypedAt, now.timeIntervalSince(lastTypedAt) > timeout {
            query = ""
        }
        lastTypedAt = now

        query.append(character)
        let primaryQuery = effectiveQuery(for: query)
        if let match = firstMatch(for: primaryQuery, in: items, currentBundleID: currentBundleID) {
            return match
        }

        query = String(character)
        return firstMatch(for: query, in: items, currentBundleID: currentBundleID)
    }

    private func effectiveQuery(for query: String) -> String {
        guard
            query.count > 1,
            let first = query.first,
            query.allSatisfy({ String($0).localizedCaseInsensitiveCompare(String(first)) == .orderedSame })
        else {
            return query
        }
        return String(first)
    }

    private func firstMatch<Item: AppTypeAheadLocatable>(
        for query: String,
        in items: [Item],
        currentBundleID: String?
    ) -> Item? {
        guard !items.isEmpty else { return nil }

        let startIndex: Int
        if
            let currentBundleID,
            let currentIndex = items.firstIndex(where: { $0.bundleID == currentBundleID })
        {
            startIndex = items.index(after: currentIndex) == items.endIndex ? items.startIndex : items.index(after: currentIndex)
        } else {
            startIndex = items.startIndex
        }

        let orderedItems = items[startIndex...] + items[..<startIndex]
        return orderedItems.first { item in
            item.name.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive, .anchored]
            ) != nil
        }
    }
}
