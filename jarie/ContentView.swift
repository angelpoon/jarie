import SwiftUI
import SwiftData
import JarieCore

struct ContentView: View {
    @Query(sort: \Capture.createdAt, order: .reverse) private var captures: [Capture]

    var body: some View {
        NavigationSplitView {
            List {
                if captures.isEmpty {
                    ContentUnavailableView(
                        "No Captures Yet",
                        systemImage: "tray",
                        description: Text("Press \u{2318}\u{21E7}J to capture text or URLs")
                    )
                } else {
                    ForEach(captures) { capture in
                        NavigationLink {
                            Text(capture.content)
                                .padding()
                        } label: {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(capture.content)
                                    .font(JarieFont.headline)
                                    .lineLimit(2)
                                Text(capture.createdAt, style: .relative)
                                    .font(JarieFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 280)
            .navigationTitle("Captures")
        } detail: {
            Text("Select a capture")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Capture.self, inMemory: true)
}
