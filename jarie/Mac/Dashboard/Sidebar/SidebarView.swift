import SwiftUI
import JarieCore

struct SidebarView: View {
    @Binding var selection: SidebarItem

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.systemImage)
                .font(JarieFont.body)
        }
        .listStyle(.sidebar)
        .navigationTitle("Jarie")
    }
}
