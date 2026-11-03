import SwiftUI

/// Bir seyahatin kişi ve masraf giriş ekranı. Her değişiklik anında kaydedilir.
struct TripDetailView: View {
    let tripID: UUID

    @Environment(TripStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    // Form alanları
    @State private var editingID: UUID?
    @State private var hasDate = false
    @State private var date = Date()
    @State private var payer: String?
    @State private var amount = ""
    @State private var note = ""
    @State private var forWhom: Set<String> = []
    @State private var showErrors = false

    @State private var newPerson = ""
    @State private var showEditTrip = false
    @State private var confirmClose = false
    @State private var showResult = false
    @State private var alertMessage: String?

    @FocusState private var focusedField: Field?
    private enum Field { case person, amount, note }
    private let formTopID = "formTop"

    init(tripID: UUID) {
        self.tripID = tripID
    }

    var body: some View {
        if let trip = store.trip(tripID) {
            content(trip)
        } else {
            ContentUnavailableView("Seyahat bulunamadı", systemImage: "suitcase")
        }
    }

    // MARK: - Ekran

    @ViewBuilder
    private func content(_ trip: Trip) -> some View {
        let money = trip.money
        ScrollViewReader { proxy in
            Form {
                if trip.closed {
                    Section {
                        Label("Bu seyahat kaydedilip kapatıldı. Masraflar yalnızca görüntülenebilir.",
                              systemImage: "lock.fill")
                        Button("Yeniden aç") {
                            store.update(tripID) { $0.closed = false }
                        }
                    }
                } else {
                    peopleSection(trip)
                    expenseFormSection(trip, money: money)
                }

                Section {
                    if trip.expenses.isEmpty {
                        Text("Henüz masraf yok.").foregroundStyle(.secondary)
                    }
                    // En yeni masraf en üstte görünür; numara giriş sırasını gösterir
                    let numbered = trip.expenses.enumerated()
                        .map { NumberedExpense(number: $0.offset + 1, expense: $0.element) }
                        .reversed()
                    ForEach(numbered) { item in
                        expenseRow(number: item.number, expense: item.expense, money: money, locked: trip.closed) {
                            loadForEditing(item.expense, money: money)
                            withAnimation { proxy.scrollTo(formTopID, anchor: .top) }
                        }
                    }
                } header: {
                    HStack {
                        Text("Masraflar (\(trip.expenses.count))")
                        Spacer()
                        Text("Toplam \(money.format(trip.totalCents))")
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(trip.title).font(.headline).lineLimit(1)
                    Text(trip.currencyLabel + (trip.closed ? " · Kapalı" : ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditTrip = true
                } label: {
                    Label("Başlık / para birimi", systemImage: "pencil")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Bitti") { focusedField = nil }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                if !trip.closed {
                    Button("Kaydet ve kapat") { confirmClose = true }
                        .buttonStyle(.bordered)
                }
                Button {
                    if trip.expenses.isEmpty {
                        alertMessage = "Hesaplamak için önce masraf ekleyin."
                    } else {
                        focusedField = nil
                        showResult = true
                    }
                } label: {
                    Text("HESAPLA").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .navigationDestination(isPresented: $showResult) {
            ResultView(
                trip: trip,
                result: Calculator.calculate(
                    people: trip.people,
                    expenses: trip.expenses,
                    decimals: trip.currency.decimals
                )
            )
        }
        .sheet(isPresented: $showEditTrip) {
            TripFormView(initial: trip, suggestedPeople: []) { r in
                store.update(tripID) {
                    $0.title = r.title
                    $0.currency = r.currency
                    $0.customCurrency = r.customCurrency
                }
                amount = "" // ondalık hanesi değişmiş olabilir
            }
        }
        .alert("\"\(trip.title)\" kaydedilip kapatılsın mı?", isPresented: $confirmClose) {
            Button("Kaydet ve kapat") {
                store.update(tripID) { $0.closed = true }
                dismiss()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Masraflar saklanır ve hesap her zaman görüntülenebilir. Kapalı seyahate yeni masraf girilmez; gerekirse yeniden açabilirsiniz.")
        }
        .alert(
            alertMessage ?? "",
            isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })
        ) {
            Button("Tamam", role: .cancel) {}
        }
    }

    // MARK: - Kişiler

    private func peopleSection(_ trip: Trip) -> some View {
        Section("Kişiler") {
            HStack {
                TextField("Kişi adı", text: $newPerson)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .person)
                    .submitLabel(.done)
                    .onSubmit { addPerson(trip) }
                Button {
                    addPerson(trip)
                } label: {
                    Label("Ekle", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .disabled(newPerson.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if trip.people.isEmpty {
                Text("Masrafa katılan kişileri ekleyin (örn. BA, AB, DYY…).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout {
                    ForEach(trip.people, id: \.self) { p in
                        PersonTag(name: p) { removePerson(p, trip: trip) }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Masraf formu

    private func expenseFormSection(_ trip: Trip, money: MoneyFormat) -> some View {
        let amountCents = money.parse(amount)
        let allSelected = !trip.people.isEmpty && Set(trip.people).isSubset(of: forWhom)

        return Section(editingID == nil ? "Yeni masraf" : "Masrafı düzenle") {
            // Tarih (isteğe bağlı)
            Toggle("Tarih ekle (isteğe bağlı)", isOn: $hasDate.animation())
                .id(formTopID)
            if hasDate {
                DatePicker("Tarih", selection: $date, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "tr_TR"))
            }

            // Kim ödedi? (zorunlu)
            VStack(alignment: .leading, spacing: 8) {
                Text("Kim ödedi? *").font(.subheadline.weight(.semibold))
                if trip.people.isEmpty {
                    errorText("Önce yukarıdan kişi ekleyin")
                }
                FlowLayout {
                    ForEach(trip.people, id: \.self) { p in
                        Chip(title: p, selected: payer == p) { payer = p }
                    }
                }
                if showErrors && payer == nil { errorText("Ödeyen kişiyi seçin") }
            }
            .padding(.vertical, 4)

            // Ne kadar ödedi? (zorunlu)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField(money.decimals == 0 ? "Ne kadar ödedi? * (örn. 1500)" : "Ne kadar ödedi? * (örn. 12,50)",
                              text: $amount)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                    Text(money.symbol).foregroundStyle(.secondary)
                }
                if showErrors && amountCents == nil { errorText("Geçerli bir tutar girin") }
            }

            // Açıklama (isteğe bağlı)
            TextField("Açıklama (isteğe bağlı)", text: $note)
                .textInputAutocapitalization(.sentences)
                .focused($focusedField, equals: .note)

            // Kimin için ödedi? (zorunlu)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Kimin için ödedi? *").font(.subheadline.weight(.semibold))
                    Spacer()
                    Button(allSelected ? "Hiçbiri" : "Hepsi") {
                        forWhom = allSelected ? [] : Set(trip.people)
                    }
                    .buttonStyle(.borderless)
                    .disabled(trip.people.isEmpty)
                }
                FlowLayout {
                    ForEach(trip.people, id: \.self) { p in
                        let on = forWhom.contains(p)
                        Chip(title: p, selected: on) {
                            if on { forWhom.remove(p) } else { forWhom.insert(p) }
                        }
                    }
                }
                if showErrors && forWhom.isEmpty { errorText("En az bir kişi seçin") }
                if let cents = amountCents, !forWhom.isEmpty {
                    let each = Int((Double(cents) / Double(forWhom.count)).rounded())
                    Text("Kişi başı pay: \(money.format(each)) (\(forWhom.count) kişi)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            HStack(spacing: 12) {
                if editingID != nil {
                    Button("Vazgeç") { resetForm() }
                        .buttonStyle(.bordered)
                }
                Button {
                    submit(trip, money: money)
                } label: {
                    Label(editingID == nil ? "Masrafı ekle" : "Güncelle",
                          systemImage: editingID == nil ? "plus" : "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Masraf satırı

    @ViewBuilder
    private func expenseRow(number: Int, expense: Expense, money: MoneyFormat, locked: Bool,
                            onEdit: @escaping () -> Void) -> some View {
        let row = HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(number). \(expense.note ?? "Açıklama yok")")
                    .font(.subheadline.weight(.semibold))
                    .italic(expense.note == nil)
                    .lineLimit(1)
                Text([expense.date, "Ödeyen: \(expense.payer)"].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Kimin için: " + expense.beneficiaries.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Text(money.format(expense.amountCents))
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
        }
        .contentShape(Rectangle())
        let highlight: Color? = editingID == expense.id ? Color.accentColor.opacity(0.12) : nil

        if locked {
            row
        } else {
            Button(action: onEdit) { row }
                .buttonStyle(.plain)
                .listRowBackground(highlight)
                .swipeActions {
                    Button(role: .destructive) {
                        deleteExpense(expense)
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                }
        }
    }

    private func errorText(_ text: String) -> some View {
        Text(text).font(.footnote).foregroundStyle(.red)
    }

    // MARK: - İşlemler

    private func resetForm() {
        editingID = nil
        hasDate = false
        date = Date()
        payer = nil
        amount = ""
        note = ""
        forWhom = []
        showErrors = false
    }

    private func submit(_ trip: Trip, money: MoneyFormat) {
        guard let selectedPayer = payer, let cents = money.parse(amount), !forWhom.isEmpty else {
            showErrors = true
            return
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        let expense = Expense(
            id: editingID ?? UUID(),
            date: hasDate ? DateText.string(from: date) : nil,
            payer: selectedPayer,
            amountCents: cents,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            beneficiaries: trip.people.filter { forWhom.contains($0) }
        )
        store.update(tripID) { t in
            if let i = t.expenses.firstIndex(where: { $0.id == expense.id }) {
                t.expenses[i] = expense
            } else {
                t.expenses.append(expense)
            }
        }
        focusedField = nil
        resetForm()
    }

    private func loadForEditing(_ e: Expense, money: MoneyFormat) {
        editingID = e.id
        if let d = DateText.date(from: e.date) {
            hasDate = true
            date = d
        } else {
            hasDate = false
        }
        payer = e.payer
        amount = money.toInput(e.amountCents)
        note = e.note ?? ""
        forWhom = Set(e.beneficiaries)
        showErrors = false
    }

    private func deleteExpense(_ e: Expense) {
        store.update(tripID) { t in t.expenses.removeAll { $0.id == e.id } }
        if editingID == e.id { resetForm() }
    }

    private func addPerson(_ trip: Trip) {
        let name = String(newPerson.trimmingCharacters(in: .whitespaces).prefix(20))
        guard !name.isEmpty else { return }
        if trip.people.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            alertMessage = "\(name) zaten listede."
            return
        }
        store.update(tripID) { $0.people.append(name) }
        newPerson = ""
    }

    private func removePerson(_ name: String, trip: Trip) {
        if trip.expenses.contains(where: { $0.payer == name || $0.beneficiaries.contains(name) }) {
            alertMessage = "\(name) masraflarda geçtiği için silinemez."
            return
        }
        store.update(tripID) { $0.people.removeAll { $0 == name } }
        if payer == name { payer = nil }
        forWhom.remove(name)
    }
}

/// Listede numarasıyla gösterilen masraf
private struct NumberedExpense: Identifiable {
    let number: Int
    let expense: Expense
    var id: UUID { expense.id }
}
