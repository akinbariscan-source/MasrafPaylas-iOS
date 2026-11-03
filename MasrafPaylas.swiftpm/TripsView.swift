import SwiftUI

/// Ana ekran: Seyahatlerim
struct TripsView: View {
    @Environment(TripStore.self) private var store
    @State private var path: [UUID] = []
    @State private var showNewTrip = false
    @State private var tripToDelete: Trip?
    @State private var openAfterSheet: UUID?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if store.trips.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hoş geldiniz").font(.headline)
                            Text("Her seyahat için ayrı bir başlık açın; masrafları girin, hesaplayın, bitince kaydedip kapatın.")
                            Text("Örneğin üç ülkelik bir Avrupa turunda \"İtalya\"yı kapatıp \"İspanya\"ya geçebilirsiniz.")
                                .foregroundStyle(.secondary)
                            Button {
                                showNewTrip = true
                            } label: {
                                Label("Yeni seyahat", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 6)
                    }
                }
                ForEach(store.trips) { trip in
                    NavigationLink(value: trip.id) {
                        TripRow(trip: trip)
                    }
                    .swipeActions {
                        Button {
                            tripToDelete = trip
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .navigationTitle("Seyahatlerim")
            .navigationDestination(for: UUID.self) { id in
                TripDetailView(tripID: id)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewTrip = true
                    } label: {
                        Label("Yeni seyahat", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewTrip, onDismiss: {
                // Yeni seyahat oluşturulduysa pencere kapanınca doğrudan onu aç
                if let id = openAfterSheet {
                    path.append(id)
                    openAfterSheet = nil
                }
            }) {
                let lastPeople = store.trips.first?.people ?? []
                TripFormView(initial: nil, suggestedPeople: lastPeople) { result in
                    let trip = store.createTrip(
                        title: result.title,
                        currency: result.currency,
                        customCurrency: result.customCurrency,
                        people: result.copyPeople ? lastPeople : []
                    )
                    openAfterSheet = trip.id
                }
            }
            .alert(
                "Seyahat silinsin mi?",
                isPresented: Binding(
                    get: { tripToDelete != nil },
                    set: { if !$0 { tripToDelete = nil } }
                ),
                presenting: tripToDelete
            ) { trip in
                Button("Sil", role: .destructive) { store.delete(trip.id) }
                Button("İptal", role: .cancel) {}
            } message: { trip in
                Text("\"\(trip.title)\" ve \(trip.expenses.count) masrafı kalıcı olarak silinecek.")
            }
        }
    }
}

private struct TripRow: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(trip.title).font(.headline).lineLimit(1)
                StatusBadge(closed: trip.closed)
            }
            Text("\(trip.currencyLabel) · \(trip.people.count) kişi · \(trip.expenses.count) masraf")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(trip.money.format(trip.totalCents))
                .font(.title3.weight(.bold))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}
