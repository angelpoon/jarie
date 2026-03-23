import SwiftUI
import SwiftData
import JarieCore

/// Navigation items for the sidebar.
enum SidebarItem: String, CaseIterable, Identifiable {
    case today = "Today"
    case all = "All"
    case starred = "Starred"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .today: "sun.max"
        case .all: "tray.full"
        case .starred: "star"
        }
    }
}

/// Root dashboard view with NavigationSplitView.
struct DashboardView: View {
    @State private var selectedSidebar: SidebarItem = .today
    @State private var selectedCaptureID: UUID?
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSidebar)
        } content: {
            CaptureListView(
                filter: selectedSidebar,
                searchText: $searchText,
                selectedCaptureID: $selectedCaptureID
            )
        } detail: {
            if let selectedCaptureID {
                CaptureDetailView(captureID: selectedCaptureID)
            } else {
                ContentUnavailableView(
                    "Select a Capture",
                    systemImage: "doc.text",
                    description: Text("Choose a capture from the list to view details")
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search captures")
        .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
    }
}
