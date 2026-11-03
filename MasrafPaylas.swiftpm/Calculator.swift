import Foundation

/// `from` kişisi `to` kişisine `cents` kuruş ödeyecek.
struct Debt: Identifiable, Hashable {
    let from: String
    let to: String
    let cents: Int
    var id: String { from + "→" + to }
}

struct PersonSummary: Identifiable {
    let name: String
    let paidCents: Int      // kişinin cebinden çıkan toplam
    let shareCents: Int     // kişinin payına düşen toplam
    let balanceCents: Int   // + alacaklı, − borçlu
    var id: String { name }
}

struct SettlementResult {
    let totalCents: Int
    let expenseCount: Int
    /// Karşılıklı borçlar mahsup edildikten sonra kalan net ödemeler (ana sonuç).
    let netDebts: [Debt]
    let summaries: [PersonSummary]
    /// Mahsup öncesi, her ikili arasındaki brüt borçlar.
    let grossDebts: [Debt]
    /// Aynı bakiyeleri en az sayıda transferle kapatan alternatif plan.
    let minTransfers: [Debt]
}

/// Hesaplama yöntemi (Android sürümü ve PDF ile aynı):
/// 1. Her masraf, "kimin için" listesindeki kişilere eşit bölünür.
/// 2. Listede olan ama masrafı ödemeyen herkes, kendi payı kadar ödeyene borçlanır.
///    (Örn. BA 150 ödedi; BA, AB, DYY, MY için → AB, DYY, MY her biri BA'ya 37,50 borçlu.)
/// 3. İki kişi birbirine borçluysa borçlar mahsup edilir; kalan net tutar ödenir.
enum Calculator {

    /// - Parameter decimals: Para biriminin ondalık hanesi. 2 → kuruşa, 0 (JPY) → tam sayıya yuvarlanır.
    static func calculate(people: [String], expenses: [Expense], decimals: Int = 2) -> SettlementResult {
        // Yuvarlama birimi (kuruş cinsinden): 2 hane → 1 kuruş, 0 hane → 100 kuruş (= 1 ¥)
        let unit = decimals >= 2 ? 1 : (decimals == 1 ? 10 : 100)
        func roundToUnit(_ x: Double) -> Int { Int((x / Double(unit)).rounded()) * unit }

        // Kişi sırası: önce kullanıcının listesi, sonra masraflarda geçip listede olmayanlar
        var names: [String] = []
        func add(_ name: String) { if !names.contains(name) { names.append(name) } }
        people.forEach(add)
        for e in expenses { add(e.payer); e.beneficiaries.forEach(add) }

        var index: [String: Int] = [:]
        for (i, name) in names.enumerated() { index[name] = i }
        let n = names.count

        // gross[borçlu][alacaklı], kuruş cinsinden (bölmeden dolayı kesirli olabilir)
        var gross = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        var paid = Array(repeating: 0, count: n)
        var share = Array(repeating: 0.0, count: n)
        var total = 0
        var count = 0

        for e in expenses {
            var bens: [String] = []
            for b in e.beneficiaries where !bens.contains(b) { bens.append(b) }
            guard !bens.isEmpty, e.amountCents > 0, let p = index[e.payer] else { continue }
            count += 1
            total += e.amountCents
            paid[p] += e.amountCents
            let perPerson = Double(e.amountCents) / Double(bens.count)
            for b in bens {
                guard let bi = index[b] else { continue }
                share[bi] += perPerson
                if bi != p { gross[bi][p] += perPerson }
            }
        }

        // Net (mahsup edilmiş) ikili borçlar
        var net: [Debt] = []
        for i in 0..<n {
            for j in (i + 1)..<n {
                let diff = gross[i][j] - gross[j][i]
                let cents = roundToUnit(abs(diff))
                if cents == 0 { continue }
                net.append(diff > 0
                    ? Debt(from: names[i], to: names[j], cents: cents)
                    : Debt(from: names[j], to: names[i], cents: cents))
            }
        }
        net.sort { (index[$0.from]!, -$0.cents) < (index[$1.from]!, -$1.cents) }

        // Bakiyeler net ödemelerden türetilir; böylece ödemeler yapılınca herkes tam sıfırlanır
        var balance = Array(repeating: 0, count: n)
        for d in net {
            balance[index[d.from]!] -= d.cents
            balance[index[d.to]!] += d.cents
        }
        let summaries = names.enumerated().map { i, name in
            PersonSummary(name: name, paidCents: paid[i], shareCents: roundToUnit(share[i]), balanceCents: balance[i])
        }

        var grossList: [Debt] = []
        for i in 0..<n {
            for j in 0..<n where i != j {
                let c = roundToUnit(gross[i][j])
                if c > 0 { grossList.append(Debt(from: names[i], to: names[j], cents: c)) }
            }
        }

        return SettlementResult(
            totalCents: total,
            expenseCount: count,
            netDebts: net,
            summaries: summaries,
            grossDebts: grossList,
            minTransfers: minimumTransfers(names: names, balance: balance)
        )
    }

    /// En büyük borçlu en büyük alacaklıya öder; bakiyeler sıfırlanana kadar tekrarlanır.
    private static func minimumTransfers(names: [String], balance: [Int]) -> [Debt] {
        // (isim, tutar, sıra) — eşit tutarlarda kişi sırası korunur
        var debtors = names.indices.filter { balance[$0] < 0 }
            .map { (name: names[$0], cents: -balance[$0], order: $0) }
            .sorted { ($1.cents, $0.order) < ($0.cents, $1.order) }
        var creditors = names.indices.filter { balance[$0] > 0 }
            .map { (name: names[$0], cents: balance[$0], order: $0) }
            .sorted { ($1.cents, $0.order) < ($0.cents, $1.order) }

        var result: [Debt] = []
        var i = 0
        var j = 0
        while i < debtors.count && j < creditors.count {
            let m = min(debtors[i].cents, creditors[j].cents)
            result.append(Debt(from: debtors[i].name, to: creditors[j].name, cents: m))
            debtors[i].cents -= m
            creditors[j].cents -= m
            if debtors[i].cents == 0 { i += 1 }
            if creditors[j].cents == 0 { j += 1 }
        }
        return result
    }
}
