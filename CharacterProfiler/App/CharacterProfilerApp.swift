// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData

private final class ModelContainerLoader: ObservableObject {
    @Published private(set) var result: Result<ModelContainer, Error>

    init() {
        result = Self.openStore()
    }

    func retry() {
        result = Self.openStore()
    }

    private static func openStore() -> Result<ModelContainer, Error> {
        let schema = Schema([
            StoryProject.self,
            CharacterProfile.self,
            ProfileSection.self,
            ProfileField.self,
            LifeEvent.self,
            PromptResponse.self,
            CharacterReferenceImage.self,
            CharacterVisualFrame.self,
            CharacterRelationship.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return .success(try ModelContainer(for: schema, configurations: [configuration]))
        } catch {
            return .failure(error)
        }
    }
}

@main
struct CharacterProfilerApp: App {
    @StateObject private var containerLoader = ModelContainerLoader()
    @State private var persistenceFailureMessage: String?

    var body: some Scene {
        WindowGroup {
            switch containerLoader.result {
            case .success(let modelContainer):
                ProjectListView()
                    .modelContainer(modelContainer)
                    .environment(\.reportPersistenceFailure) { message in
                        persistenceFailureMessage = message
                    }
                    .alert("Changes Could Not Be Saved", isPresented: Binding(
                        get: { persistenceFailureMessage != nil },
                        set: { if !$0 { persistenceFailureMessage = nil } }
                    )) {
                        Button("OK", role: .cancel) { persistenceFailureMessage = nil }
                    } message: {
                        Text(persistenceFailureMessage ?? "Unknown persistence error.")
                    }
            case .failure(let error):
                DataStoreUnavailableView(error: error, retry: containerLoader.retry)
            }
        }
    }
}

private struct DataStoreUnavailableView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Story Library Unavailable", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            VStack(spacing: 10) {
                Text("Character Profiler could not open its local story database. The app will not erase or replace the store automatically.")
                Text("You can retry opening the preserved library. If the problem continues, preserve the app's data before reinstalling so the story library can be recovered or inspected.")
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Button("Retry Opening Library", action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
