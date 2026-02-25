import Foundation

/// Small deterministic queue helper for session-like flows:
/// - `current` = first
/// - `popCurrent()` removes first
/// - `moveCurrentNearEnd(window:)` moves first into near-end window (like "Показать ещё")
struct SessionQueue<Element> {
    private(set) var items: [Element]
    private let id: (Element) -> String

    init(items: [Element] = [], id: @escaping (Element) -> String) {
        self.items = items
        self.id = id
    }

    var count: Int { items.count }
    var isEmpty: Bool { items.isEmpty }
    var current: Element? { items.first }

    mutating func setItems(_ newItems: [Element]) {
        items = newItems
    }

    @discardableResult
    mutating func popCurrent() -> Element? {
        guard !items.isEmpty else { return nil }
        return items.removeFirst()
    }

    /// Moves current element to a random position inside the last `window` elements.
    /// Example: window=3 => insert somewhere in [count-window ... count]
    mutating func moveCurrentNearEnd(window: Int) {
        guard items.count > 1 else { return }
        let w = max(1, window)

        let item = items.removeFirst()

        let n = items.count
        let actualWindow = min(w, n)
        let startIndex = max(0, n - actualWindow)
        let insertIndex = Int.random(in: startIndex...n) // n == append

        items.insert(item, at: insertIndex)
    }

    func containsId(_ elementId: String) -> Bool {
        items.contains { id($0) == elementId }
    }

    func currentId() -> String? {
        guard let cur = current else { return nil }
        return id(cur)
    }
}
