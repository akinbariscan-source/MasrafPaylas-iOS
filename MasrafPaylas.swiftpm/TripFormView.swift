import SwiftUI

/// Yeni seyahat / seyahati düzenle: başlık + para birimi (+ kişileri kopyala)
struct TripFormView: View {
    struct Result {
        var title: String
        var currency: Currency
        var customCurrency: String?
        var copyPeople: Bool
    }

    let initial: Trip?
    let suggestedPeople: [String]
    let onSave: (Result) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var currency: Currency
    @State private var custom: String
    @State private var copyPeople: Bool

    init(initial: Trip?, suggestedPeople: [String], onSave: @escaping (Result) -> Void) {
        self.initial = initial
        self.suggestedPeople = suggestedPeople
        self.onSave = onSave
        _title = State(initialValue: initial?.title ?? "")
        _currency = State(initialValue: initial?.currency ?? .TRY)
        _custom = State(initialValue: initial?.customCurrency ?? "")
        _copyPeople = State(initialValue: !suggestedPeople.isEmpty)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && (currency != .OTHER || !custom.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Seyahat başlığı") {
                    TextField("örn. İtalya", text: $title)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    Picker("Para birimi", selection: $currency) {
                        ForEach(Currency.allCases) { c in
                            Text(c.pickerLabel).tag(c)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()

                    if currency == .OTHER {
                        TextField("Para birimi kodu / simgesi, örn. CHF", text: $custom)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Para birimi")
                } footer: {
                    if currency.decimals == 0 {
                        Text("Japon Yeni kuruşsuzdur; tutarlar ve borçlar tam sayıya yuvarlanır.")
                    }
                }

                if initial == nil && !suggestedPeople.isEmpty {
                    Section {
                        Toggle("Kişileri önceki seyahatten al", isOn: $copyPeople)
                    } footer: {
                        Text(suggestedPeople.joined(separator: ", "))
                    }
                }
            }
            .navigationTitle(initial == nil ? "Yeni seyahat" : "Seyahati düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(initial == nil ? "Oluştur" : "Kaydet") {
                        let trimmedCustom = custom.trimmingCharacters(in: .whitespaces)
                        onSave(Result(
                            title: title.trimmingCharacters(in: .whitespaces),
                            currency: currency,
                            customCurrency: currency == .OTHER ? String(trimmedCustom.prefix(6)) : nil,
                            copyPeople: copyPeople
                        ))
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
