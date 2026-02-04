import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query private var events: [HistoryEventEntity]

    var grouped: [String: [HistoryEventEntity]] {
        Dictionary(grouping: events) { $0.dateBucket }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(grouped.keys.sorted(by: >), id: \.self) { day in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(day)
                                .font(.headline)
                            WrapView(items: grouped[day] ?? []) { event in
                                Text(event.eventType.capitalized)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.stackCard)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.stackBackground.ignoresSafeArea())
            .navigationTitle("History")
        }
    }
}

struct WrapView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading) {
            FlexibleView(data: items, spacing: 8, alignment: .leading) { item in
                content(item)
            }
        }
    }
}

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return GeometryReader { geometry in
            ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
                ForEach(data) { item in
                    content(item)
                        .alignmentGuide(.leading) { dimension in
                            if abs(width - dimension.width) > geometry.size.width {
                                width = 0
                                height -= dimension.height + spacing
                            }
                            let result = width
                            if item.id == data.last?.id {
                                width = 0
                            } else {
                                width -= dimension.width + spacing
                            }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item.id == data.last?.id {
                                height = 0
                            }
                            return result
                        }
                }
            }
        }
        .frame(height: 80)
    }
}
