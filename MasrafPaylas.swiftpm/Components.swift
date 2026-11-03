import SwiftUI

/// Seçilebilir kişi düğmesi (Android'deki FilterChip karşılığı)
struct Chip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if selected {
                    Image(systemName: "checkmark").font(.caption.weight(.bold))
                }
                Text(title).font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                selected ? Color.accentColor.opacity(0.18) : Color(.secondarySystemFill),
                in: Capsule()
            )
            .foregroundStyle(selected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain) // Form satırında her düğme ayrı ayrı dokunulabilir olsun
    }
}

/// Kişi listesindeki silinebilir etiket
struct PersonTag: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(name).font(.subheadline.weight(.medium))
            Button(action: onRemove) {
                Image(systemName: "xmark").font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(name) kişisini sil")
        }
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .padding(.vertical, 7)
        .overlay(Capsule().stroke(Color(.separator)))
    }
}

/// "BA" gibi küçük isim rozeti
struct PersonBadge: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
    }
}

/// "Açık" / "Kapalı" durum etiketi
struct StatusBadge: View {
    let closed: Bool

    var body: some View {
        HStack(spacing: 3) {
            if closed { Image(systemName: "lock.fill") }
            Text(closed ? "Kapalı" : "Açık")
        }
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(
            closed ? Color(.tertiarySystemFill) : Color.accentColor.opacity(0.18),
            in: RoundedRectangle(cornerRadius: 5)
        )
        .foregroundStyle(closed ? Color.secondary : Color.accentColor)
    }
}

/// Öğeleri satıra sığdığı kadar dizip taşanı alt satıra geçiren yerleşim (FlowRow karşılığı)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var width: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            width = max(width, x - spacing)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
