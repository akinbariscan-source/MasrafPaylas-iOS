import Foundation

/// Tutar biçimlendirme ve okuma. Tutarlar uygulama içinde her zaman kuruş (1/100) olarak tutulur.
/// Kuruşsuz para birimlerinde (JPY) `decimals` = 0 olur; tutarlar tam sayıya yuvarlanır.
/// Sayılar Türkçe biçimde gösterilir: 1.234,56 €
struct MoneyFormat {
    let symbol: String
    let decimals: Int

    private static let turkish = Locale(identifier: "tr_TR")
    private static let posix = Locale(identifier: "en_US_POSIX")

    private func formatter(grouping: Bool) -> NumberFormatter {
        let f = NumberFormatter()
        f.locale = Self.turkish
        f.numberStyle = .decimal
        f.usesGroupingSeparator = grouping
        f.minimumFractionDigits = decimals
        f.maximumFractionDigits = decimals
        f.roundingMode = .halfUp
        return f
    }

    private func decimal(_ cents: Int) -> NSDecimalNumber {
        NSDecimalNumber(decimal: Decimal(cents) / 100)
    }

    /// 123456 → "1.234,56 €"  (JPY: 150000 → "1.500 ¥")
    func format(_ cents: Int) -> String {
        (formatter(grouping: true).string(from: decimal(cents)) ?? "\(cents)") + " " + symbol
    }

    /// 15067 → "+150,67 €", -3703 → "−37,03 €"
    func signed(_ cents: Int) -> String {
        if cents > 0 { return "+" + format(cents) }
        if cents < 0 { return "−" + format(-cents) }
        return format(0)
    }

    /// "12,5" / "12.50" / "1.234,56" / "2.500" → kuruş. Geçersiz ya da sıfır/negatifse nil.
    func parse(_ text: String) -> Int? {
        var t = text.replacingOccurrences(of: " ", with: "")
        if t.isEmpty { return nil }
        if t.contains(",") {
            // Türkçe biçim: 1.234,56
            t = t.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        } else if t.range(of: #"^\d{1,3}(\.\d{3})+$"#, options: .regularExpression) != nil {
            // 2.500 / 1.250.000 → binlik ayırıcı
            t = t.replacingOccurrences(of: ".", with: "")
        }
        guard t.range(of: #"^\d+(\.\d+)?$"#, options: .regularExpression) != nil,
              var value = Decimal(string: t, locale: Self.posix) else { return nil }
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, decimals, .plain)
        guard rounded > 0 else { return nil }
        return NSDecimalNumber(decimal: rounded * 100).intValue
    }

    /// kuruş → form alanında düzenlenecek metin: 1250 → "12,50"  (JPY: 150000 → "1500")
    func toInput(_ cents: Int) -> String {
        formatter(grouping: false).string(from: decimal(cents)) ?? "\(cents / 100)"
    }
}

/// Tarih alanı "GG.AA.YYYY" biçiminde saklanır.
enum DateText {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()

    static func string(from date: Date) -> String { formatter.string(from: date) }
    static func date(from text: String?) -> Date? { text.flatMap { formatter.date(from: $0) } }
}
