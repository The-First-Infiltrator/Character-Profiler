// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI

private enum CharacterDetailSection: String, CaseIterable, Identifiable {
    case profile, guide, people, history, visual
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

/// The character record shell. Feature-heavy workspaces live in dedicated view files so their
/// persistence and graph invariants can be reviewed and tested independently.
struct CharacterDetailView: View {
    let character: CharacterProfile
    @State private var selectedSection: CharacterDetailSection = .profile
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                CharacterHeader(character: character)
                Picker("Character section", selection: $selectedSection) {
                    ForEach(CharacterDetailSection.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Choose which part of the character record to view")

                switch selectedSection {
                case .profile:
                    CharacterProfilePanel(character: character)
                case .guide:
                    if let project = character.project {
                        CharacterGuidePanel(character: character, project: project)
                    } else {
                        ContentUnavailableView(
                            "Guide Unavailable",
                            systemImage: "books.vertical",
                            description: Text("Assign this character to a story before using the Character Guide.")
                        )
                    }
                case .people:
                    if let project = character.project {
                        CharacterRelationshipsPanel(character: character, project: project)
                    } else {
                        ContentUnavailableView(
                            "Relationships Unavailable",
                            systemImage: "person.2.slash",
                            description: Text("Assign this character to a story before linking people.")
                        )
                    }
                case .history:
                    CharacterTimelinePanel(character: character)
                case .visual:
                    if #available(iOS 18.1, *) {
                        CharacterVisualWorkspaceView(character: character)
                    } else {
                        VisualFeatureUnavailableView()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if character.project != nil {
                Button("Edit Character", systemImage: "pencil") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let project = character.project {
                NavigationStack { CharacterEditorView(project: project, character: character) }
            }
        }
    }
}

private struct CharacterHeader: View {
    let character: CharacterProfile

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            CharacterPortraitView(character: character, size: 92)
            VStack(alignment: .leading, spacing: 6) {
                Text(character.displayName).font(.title2.bold())
                if !character.storyRole.isEmpty { Text(character.storyRole).foregroundStyle(.secondary) }
                HStack(spacing: 12) {
                    if !character.ageText.isEmpty { Label(character.ageText, systemImage: "birthday.cake") }
                    if !character.pronouns.isEmpty { Text(character.pronouns) }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                ProgressView(value: character.completionScore)
                    .accessibilityLabel("Character development")
                    .accessibilityValue("\(Int(character.completionScore * 100)) percent")
                Text("\(Int(character.completionScore * 100))% developed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CharacterProfilePanel: View {
    let character: CharacterProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !character.summary.isEmpty { Text(character.summary).font(.body) }
            let populatedSections = character.sortedSections.filter { section in
                section.fields.contains { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }
            if populatedSections.isEmpty && character.summary.isEmpty {
                ContentUnavailableView(
                    "Profile Is Still Empty",
                    systemImage: "person.text.rectangle",
                    description: Text("Use Edit Character to add flexible profile sections and facts.")
                )
            } else {
                ForEach(populatedSections) { section in
                    GroupBox(section.title) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(section.sortedFields) { field in
                                if !field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(field.label).font(.caption).foregroundStyle(.secondary)
                                        Text(field.value).frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

struct VisualFeatureUnavailableView: View {
    var body: some View {
        ContentUnavailableView(
            "Visual AI Requires a Newer System",
            systemImage: "sparkles",
            description: Text("Character profiles, relationships, history and the Character Guide remain fully available. Visual AI uses Apple's Image Playground on supported devices.")
        )
    }
}
