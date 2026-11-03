import SwiftUI

/// Hesap sonucu: net ödemeler, kişi bazında özet, brüt borçlar, en az transfer
struct ResultView: View {
    let trip: Trip
    let result: SettlementResult

    init(trip: Trip, result: SettlementResult) {
        self.trip = trip
        self.result = result
    }

    private var money: MoneyFormat { trip.money }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam harcama").font(.subheadline.weight(.medium))
                    Text(money.format(result.totalCents))
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                    Text("\(result.expenseCount) masraf · \(result.summaries.count) kişi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section {
                if result.netDebts.isEmpty {
                    Text("Borç yok, herkes ödeşmiş görünüyor.")
                }
                ForEach(result.netDebts) { DebtRow(debt: $0, money: money, emphasize: true) }
            } header: {
                Text("Kim kime ne kadar ödeyecek?")
            } footer: {
                Text("Karşılıklı borçlar mahsup edildi; bu \(result.netDebts.count) ödeme yapıldığında herkes ödeşmiş olur.")
            }

            Section {
                SummaryRow(name: "Kişi", paid: "Ödediği", share: "Payı", balance: "Bakiye",
                           balanceColor: .secondary, header: true)
                ForEach(result.summaries) { s in
                    SummaryRow(
                        name: s.name,
                        paid: money.format(s.paidCents),
                        share: money.format(s.shareCents),
                        balance: money.signed(s.balanceCents),
                        balanceColor: s.balanceCents > 0 ? .green : (s.balanceCents < 0 ? .red : .primary),
                        header: false
                    )
                }
            } header: {
                Text("Kişi bazında özet")
            } footer: {
                Text("Bakiye = ödediği − payına düşen. Artı: alacaklı, eksi: borçlu.")
            }

            Section {
                ForEach(result.grossDebts) { DebtRow(debt: $0, money: money, emphasize: false) }
            } header: {
                Text("Brüt borçlar (mahsup öncesi)")
            } footer: {
                Text("Soldaki kişinin, sağdakinin ödediği masraflardan doğan borcu.")
            }

            Section {
                ForEach(result.minTransfers) { DebtRow(debt: $0, money: money, emphasize: false) }
            } header: {
                Text("Alternatif: En az transferle kapatma")
            } footer: {
                Text("Kimin kime ödediği önemli değilse aynı bakiyeler \(result.minTransfers.count) transferle de kapanır.")
            }

            Section {
                Text("Yöntem: Her masraf, \"kimin için\" seçilen kişilere eşit bölünür. Listede olup masrafı ödemeyen herkes, kendi payı kadar ödeyene borçlanır. Kendi için yapılan masraf borç oluşturmaz.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Hesap Sonucu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Hesap Sonucu").font(.headline)
                    Text(trip.title).font(.caption).foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: shareText) {
                    Label("Sonucu paylaş", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private var shareText: String {
        var lines = [
            "\(trip.title) – Masraf Paylaşım Hesabı",
            "Toplam: \(money.format(result.totalCents)) (\(result.expenseCount) masraf)",
            "",
            "Kim kime ne kadar ödeyecek:",
        ]
        lines += result.netDebts.map { "• \($0.from) → \($0.to): \(money.format($0.cents))" }
        lines += ["", "Kişi bazında bakiye:"]
        lines += result.summaries.map { "• \($0.name): \(money.signed($0.balanceCents))" }
        return lines.joined(separator: "\n")
    }
}

private struct DebtRow: View {
    let debt: Debt
    let money: MoneyFormat
    let emphasize: Bool

    var body: some View {
        HStack(spacing: 8) {
            PersonBadge(name: debt.from)
            Image(systemName: "arrow.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityLabel("ödeyecek")
            PersonBadge(name: debt.to)
            Spacer()
            Text(money.format(debt.cents))
                .font(emphasize ? .headline : .body)
                .monospacedDigit()
        }
    }
}

private struct SummaryRow: View {
    let name: String
    let paid: String
    let share: String
    let balance: String
    let balanceColor: Color
    let header: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .fontWeight(.semibold)
                .frame(width: 44, alignment: .leading)
            Text(paid).frame(maxWidth: .infinity, alignment: .trailing)
            Text(share).frame(maxWidth: .infinity, alignment: .trailing)
            Text(balance)
                .fontWeight(.semibold)
                .foregroundStyle(balanceColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(header ? .caption.weight(.semibold) : .caption)
        .foregroundStyle(header ? Color.secondary : Color.primary)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}
