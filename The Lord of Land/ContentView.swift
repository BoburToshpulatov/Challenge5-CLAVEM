//
//  RootView.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 21/02/26.
//

import SwiftUI

struct ContentView: View {
    @State private var store = MockData.makeStore()
    @State private var searchString = ""

    var body: some View {
        TabView {

            Tab("Home", systemImage: "house") {
                NavigationStack {
                    HomeView(store: store)
                }
            }

//            Tab("Reminders", systemImage: "bell") {
//                NavigationStack {
//                    RemindersView(store: store)
//                }
//            }

            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                        .navigationTitle("Settings")
                }
            }

            Tab(role: .search) {
                NavigationStack {
                    List {
                        Text("Search screen")
                        Text("Search screen2")
                    }
                    .navigationTitle("Search")
                    .searchable(text: $searchString)
                }
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
    }
}

#Preview {
    ContentView()
}

