import SwiftUI
import SwiftData
import JarieCore

struct CaptureListView: View {
    let filter: SidebarItem
    @Binding var searchText: String
    @Binding var selectedCaptureID: UUID?

    @Query(sort: \Capture.createdAt, order: .reverse) private var allCaptures: [Capture]

    private var filteredCaptures: [Capture] {
        var captures = allCaptures.filter { !$0.isDeleted }

        switch filter {
        case .today:
            captures = captures.filter { DateFormatters.isToday($0.createdAt) }
        case .all:
            break
        case .starred:
            captures = captures.filter { $0.isFavorite }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            captures = captures.filter {
                $0.content.lowercased().contains(query) ||
                ($0.sourceTitle?.lowercased().contains(query) ?? false) ||
                ($0.sourceURL?.lowercased().contains(query) ?? false)
            }
        }

        return captures
    }

    /// Groups captures by calendar date.
    private var groupedCaptures: [(String, [Capture])] {
        let grouped = Dictionary(grouping: filteredCaptures) { capture in
            dateLabel(for: capture.createdAt)
        }
        // Sort groups by the first capture's date (newest first)
        return grouped.sorted { lhs, rhs in
            guard let lDate = lhs.value.first?.createdAt,
                  let rDate = rhs.value.first?.createdAt else { return false }
            return lDate > rDate
        }
    }

    var body: some View {
        Group {
            if filteredCaptures.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(selection: $selectedCaptureID) {
                    ForEach(groupedCaptures, id: \.0) { dateLabel, captures in
                        Section(dateLabel) {
                            ForEach(captures) { capture in
                                CaptureRowView(capture: capture)
                                    .tag(capture.id)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            softDelete(capture)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            capture.isFavorite.toggle()
                                        } label: {
                                            Label(
                                                capture.isFavorite ? "Unstar" : "Star",
                                                systemImage: capture.isFavorite ? "star.slash" : "star.fill"
                                            )
                                        }
                                        .tint(Color("JariePink"))
                                    }
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle(filter.rawValue)
    }

    // MARK: - Helpers

    @Environment(\.modelContext) private var modelContext

    private func softDelete(_ capture: Capture) {
        capture.isDeleted = true
        // Register undo
        modelContext.undoManager?.registerUndo(withTarget: capture) { target in
            target.isDeleted = false
        }
        modelContext.undoManager?.setActionName("Delete Capture")
    }

    private func dateLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return DateFormatters.fullDate.string(from: date)
        }
    }
}
