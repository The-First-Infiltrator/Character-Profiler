// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData

@main
struct CharacterProfilerApp: App {
    private let modelContainer: ModelContainer = {
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
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create Character Profiler data store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ProjectListView()
        }
        .modelContainer(modelContainer)
    }
}
