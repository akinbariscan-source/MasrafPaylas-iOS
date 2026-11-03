import Foundation
import Observation

/// Tüm seyahatleri telefonda (uygulamanın Belgeler klasöründe, trips.json) saklar.
/// Her değişiklik anında kaydedilir.
@Observable
final class TripStore {
    private(set) var trips: [Trip] = []

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("trips.json")
        load()
    }

    func trip(_ id: UUID) -> Trip? {
        trips.first { $0.id == id }
    }

    /// Yeni seyahat en üstte görünür.
    @discardableResult
    func createTrip(title: String, currency: Currency, customCurrency: String?, people: [String]) -> Trip {
        let trip = Trip(title: title, currency: currency, customCurrency: customCurrency, people: people)
        trips.insert(trip, at: 0)
        save()
        return trip
    }

    func update(_ id: UUID, _ change: (inout Trip) -> Void) {
        guard let i = trips.firstIndex(where: { $0.id == id }) else { return }
        change(&trips[i])
        save()
    }

    func delete(_ id: UUID) {
        trips.removeAll { $0.id == id }
        save()
    }

    // MARK: - Dosya

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            trips = try JSONDecoder().decode([Trip].self, from: data)
        } catch {
            print("Seyahatler okunamadı: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(trips)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Seyahatler kaydedilemedi: \(error)")
        }
    }
}
