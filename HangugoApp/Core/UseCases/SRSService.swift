import Foundation

final class SRSService {
    
    private let store: SRSStore
    private var cached: [SRSItem] = []
    
    init(store: SRSStore) {
        self.store = store
    }
    
    func load() throws {
        cached = try store.load()
    }
    
    func dueItems(on date: Date = Date()) -> [SRSItem] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return cached.filter { $0.dueDate <= startOfDay }
    }
    
    /// Создаёт SRSItem для слова, если его ещё нет (для MVP-инициализации)
    func ensureItemExists(for wordId: String, today: Date = Date()) {
        guard !cached.contains(where: { $0.wordId == wordId }) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: today)
        let new = SRSItem(
            wordId: wordId,
            repetitions: 0,
            intervalDays: 0,
            easeFactor: 2.5,     // стандартная стартовая EF в SM-2
            dueDate: startOfDay, // можно считать “на сегодня”
            lapses: 0,
            lastReviewedAt: nil
        )
        cached.append(new)
    }
    
    func upsert(_ item: SRSItem) {
        if let idx = cached.firstIndex(where: { $0.wordId == item.wordId }) {
            cached[idx] = item
        } else {
            cached.append(item)
        }
    }
    
    func persist() throws {
        try store.save(cached)
    }
    
    func snoozeToTomorrow(wordId: String, now: Date = Date()) {
        let startOfToday = Calendar.current.startOfDay(for: now)
        guard let idx = cached.firstIndex(where: { $0.wordId == wordId }) else { return }
        
        cached[idx].lastReviewedAt = now
        cached[idx].dueDate = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
    }
    
    func applySM2(wordId: String, rating: ReviewRating, now: Date = Date()) {
        guard let idx = cached.firstIndex(where: { $0.wordId == wordId }) else { return }
        
        var item = cached[idx]
        let q = rating.quality
        let today = Calendar.current.startOfDay(for: now)
        
        if q < 3 {
            // Fail
            item.repetitions = 0
            item.intervalDays = 1
            item.lapses += 1
        } else {
            // Success
            item.repetitions += 1
            
            if item.repetitions == 1 {
                item.intervalDays = 1
            } else if item.repetitions == 2 {
                item.intervalDays = 6
            } else {
                // repetitions >= 3
                let next = Int((Double(item.intervalDays) * item.easeFactor).rounded())
                item.intervalDays = max(1, next)
            }
            
            // EF update (SM-2)
            let dq = Double(5 - q)
            let newEF = item.easeFactor + (0.1 - dq * (0.08 + dq * 0.02))
            item.easeFactor = max(1.3, newEF)
        }
        
        item.lastReviewedAt = now
        item.dueDate = Calendar.current.date(byAdding: .day, value: item.intervalDays, to: today) ?? today
        
        cached[idx] = item
    }
    
    func addNewWordToSRS(wordId: String, now: Date = Date(), firstReviewTomorrow: Bool = true) {
        // если уже есть — ничего не делаем
        guard !cached.contains(where: { $0.wordId == wordId }) else { return }
        
        let today = Calendar.current.startOfDay(for: now)
        let due: Date
        if firstReviewTomorrow {
            due = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        } else {
            due = today
        }
        
        let item = SRSItem(
            wordId: wordId,
            repetitions: 0,
            intervalDays: 0,
            easeFactor: 2.5,
            dueDate: due,
            lapses: 0,
            lastReviewedAt: nil
        )
        cached.append(item)
    }
    
    func allWordIds() -> [String] {
        cached.map { $0.wordId }
    }
}
