// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData

@main
struct CharacterProfilerApp: App {
    private let containerResult: Result<ModelContainer, Error> = {
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
    }()

    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case .success(let modelContainer):
                ProjectListView()
                    .modelContainer(modelContainer)
            case .failure(let error):
                DataStoreUnavailableView(error: error)
            }
        }
    }
}

private struct DataStoreUnavailableView: View {
    let error: Error

    var body: some View {
        ContentUnavailableView {
            Label("Story Library Unavailable", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            VStack(spacing: 10) {
                Text("Character Profiler could not open its local story database. The app will not erase or replace the store automatically.")
                Text("Close and reopen the app. If the problem continues, preserve the app's data before reinstalling so the story library can be recovered or inspected.")
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding()
    }
}
