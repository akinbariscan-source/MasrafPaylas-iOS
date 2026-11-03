import Foundation

/// Seçilebilir para birimleri. Japon Yeni kuruşsuzdur (decimals = 0).
enum Currency: String, Codable, CaseIterable, Identifiable {
    case TRY, EUR, USD, GBP, JPY, OTHER

    var id: String { rawValue }

    var label: String {
        switch self {
        case .TRY: return "Türk Lirası"
        case .EUR: return "Euro"
        case .USD: return "ABD Doları"
        case .GBP: return "İngiliz Sterlini"
        case .JPY: return "Japon Yeni"
        case .OTHER: return "Diğer"
        }
    }

    var symbol: String {
        switch self {
        case .TRY: return "₺"
        case .EUR: return "€"
        case .USD: return "$"
        case .GBP: return "£"
        case .JPY: return "¥"
        case .OTHER: return ""
        }
    }

    var decimals: Int { self == .JPY ? 0 : 2 }

    /// Seçim listesinde görünen ad: "€ Euro (EUR)", "Diğer"
    var pickerLabel: String {
        self == .OTHER ? label : "\(symbol) \(label) (\(rawValue))"
    }
}

/// Tek bir masraf kaydı. Tutar her zaman kuruş (1/100) olarak tutulur: 12,50 → 1250
struct Expense: Identifiable, Codable, Hashable {
    var id = UUID()
    /// İsteğe bağlı tarih, "GG.AA.YYYY"
    var date: String?
    /// Kim ödedi (zorunlu)
    var payer: String
    /// Ne kadar ödedi, kuruş (zorunlu)
    var amountCents: Int
    /// Kısa açıklama (isteğe bağlı)
    var note: String?
    /// Kimin için ödedi (zorunlu, en az 1 kişi)
    var beneficiaries: [String]
}

/// Bir seyahat: kendi başlığı, para birimi, kişileri ve masrafları vardır.
/// Örn. "İtalya" (EUR) kaydedilip kapatılır, ardından "İspanya" (EUR) başlatılır.
struct Trip: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var currency: Currency
    /// Para birimi "Diğer" ise kullanıcının yazdığı kod/simge, örn. "CHF"
    var customCurrency: String?
    var people: [String] = []
    var expenses: [Expense] = []
    /// Kaydedilip kapatılan seyahate yeni masraf girilmez (yeniden açılabilir).
    var closed = false
    var createdAt = Date()

    var currencySymbol: String {
        guard currency == .OTHER else { return currency.symbol }
        let custom = (customCurrency ?? "").trimmingCharacters(in: .whitespaces)
        return custom.isEmpty ? "¤" : custom
    }

    /// "€ Euro", "CHF (Diğer)"
    var currencyLabel: String {
        currency == .OTHER ? "\(currencySymbol) (Diğer)" : "\(currency.symbol) \(currency.label)"
    }

    var money: MoneyFormat { MoneyFormat(symbol: currencySymbol, decimals: currency.decimals) }

    var totalCents: Int { expenses.reduce(0) { $0 + $1.amountCents } }
}
