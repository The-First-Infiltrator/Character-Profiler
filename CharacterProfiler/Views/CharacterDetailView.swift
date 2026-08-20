// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData

/// Character home screen. Heavy workspaces are intentionally separate navigation destinations so
/// the iPhone experience stays readable and each task gets enough room to breathe.
struct CharacterDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteErrorMessage: String?

    private var profileFactCount: Int {
        character.sections.reduce(0) { total, section in
            total + section.fields.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        }
    }

    private var guideAnswerCount: Int {
        character.promptResponses.filter {
            !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
    }

    private var relationshipCount: Int { Set(character.allRelationships.map(\.id)).count }
    private var historyCount: Int { character.lifeEvents.count }
    private var visualAssetCount: Int {
        character.referenceImages.count + character.visualFrames.count
            + (character.profileImageData == nil ? 0 : 1)
            + (character.generatedVisualData == nil ? 0 : 1)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                CharacterHeader(character: character)

                if !character.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(character.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Character Workspace")
                        .font(.title3.bold())
                    Text("Open the part of this character you want to work on. Each area keeps its own tools and editing flow.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    CharacterProfileWorkspaceView(character: character)
                } label: {
                    CharacterWorkspaceCard(
                        title: "Profile",
                        subtitle: profileFactCount == 0 ? "Build identity, personality and custom facts" : "Review identity and \(profileFactCount) saved fact\(profileFactCount == 1 ? "" : "s")",
                        systemImage: "person.text.rectangle",
                        badge: profileFactCount == 0 ? "Start" : "\(profileFactCount)"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workspace-profile")

                if let project = character.project {
                    NavigationLink {
                        CharacterGuideWorkspaceView(character: character, project: project)
                    } label: {
                        CharacterWorkspaceCard(
                            title: "Character Guide",
                            subtitle: guideAnswerCount == 0 ? "Answer adaptive development questions" : "Continue development from \(guideAnswerCount) saved answer\(guideAnswerCount == 1 ? "" : "s")",
                            systemImage: "sparkles",
                            badge: guideAnswerCount == 0 ? "Explore" : "\(guideAnswerCount)"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("workspace-guide")

                    NavigationLink {
                        CharacterRelationshipsWorkspaceView(character: character, project: project)
                    } label: {
                        CharacterWorkspaceCard(
                            title: "People & Relationships",
                            subtitle: relationshipCount == 0 ? "Connect family, friends, rivals and partners" : "\(relationshipCount) relationship\(relationshipCount == 1 ? "" : "s") linked to this character",
                            systemImage: "person.2",
                            badge: relationshipCount == 0 ? "Add" : "\(relationshipCount)"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("workspace-relationships")
                } else {
                    CharacterWorkspaceCard(
                        title: "Character Guide",
                        subtitle: "Assign this character to a story to use the Guide",
                        systemImage: "sparkles",
                        badge: "Unavailable"
                    )
                    CharacterWorkspaceCard(
                        title: "People & Relationships",
                        subtitle: "Assign this character to a story to link people",
                        systemImage: "person.2",
                        badge: "Unavailable"
                    )
                }

                NavigationLink {
                    CharacterHistoryWorkspaceView(character: character)
                } label: {
                    CharacterWorkspaceCard(
                        title: "History",
                        subtitle: historyCount == 0 ? "Record the events that shaped this character" : "\(historyCount) life event\(historyCount == 1 ? "" : "s") in chronological order",
                        systemImage: "clock.arrow.circlepath",
                        badge: historyCount == 0 ? "Add" : "\(historyCount)"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workspace-history")
                .accessibilityLabel("History")

                NavigationLink {
                    CharacterVisualWorkspaceScreen(character: character)
                } label: {
                    CharacterWorkspaceCard(
                        title: "Visual Studio",
                        subtitle: visualAssetCount == 0 ? "Develop a consistent visual identity" : "Work with \(visualAssetCount) portrait, reference or generated asset\(visualAssetCount == 1 ? "" : "s")",
                        systemImage: "person.crop.rectangle.stack",
                        badge: visualAssetCount == 0 ? "Open" : "\(visualAssetCount)"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workspace-visual")
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if character.project != nil {
                Menu {
                    Button { showingEditor = true } label: {
                        Label("Edit Character", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                        Label("Delete Character", systemImage: "trash")
                    }
                } label: {
                    Label("Character Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let project = character.project {
                NavigationStack { CharacterEditorView(project: project, character: character) }
            }
        }
        .confirmationDialog(
            "Delete Character?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Character Permanently", role: .destructive) { deleteCharacter() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(characterDeletionMessage)
        }
        .alert("Character Could Not Be Deleted", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "Unknown delete error.")
        }
    }

    private var characterDeletionMessage: String {
        let answerCount = guideAnswerCount
        return "This permanently deletes \(character.displayName) and removes \(relationshipCount) linked relationship\(relationshipCount == 1 ? "" : "s"), \(historyCount) history entr\(historyCount == 1 ? "y" : "ies"), \(answerCount) Guide answer\(answerCount == 1 ? "" : "s"), and \(visualAssetCount) visual asset\(visualAssetCount == 1 ? "" : "s"). Export the story backup first if you may need this character again."
    }

    private func deleteCharacter() {
        let project = character.project
        modelContext.delete(character)
        project?.updatedAt = .now
        do {
            try modelContext.saveOrRollback()
            dismiss()
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }
}

private struct CharacterHeader: View {
    let character: CharacterProfile

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            CharacterPortraitView(character: character, size: 96)
            VStack(alignment: .leading, spacing: 7) {
                Text(character.displayName)
                    .font(.title2.bold())
                    .lineLimit(2)
                if !character.storyRole.isEmpty {
                    Text(character.storyRole)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 10) {
                    if !character.ageText.isEmpty {
                        Label(character.ageText, systemImage: "birthday.cake")
                    }
                    if !character.pronouns.isEmpty { Text(character.pronouns) }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                ProgressView(value: character.completionScore)
                    .accessibilityLabel("Character development")
                    .accessibilityValue("\(Int(character.completionScore * 100)) percent")
                Text("\(Int(character.completionScore * 100))% developed")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct CharacterWorkspaceCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let badge: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Text(badge)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CharacterProfileWorkspaceView: View {
    let character: CharacterProfile

    var body: some View {
        ScrollView {
            CharacterProfilePanel(character: character)
                .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterGuideWorkspaceView: View {
    let character: CharacterProfile
    let project: StoryProject

    var body: some View {
        ScrollView {
            CharacterGuidePanel(character: character, project: project)
                .padding()
        }
        .navigationTitle("Character Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterRelationshipsWorkspaceView: View {
    let character: CharacterProfile
    let project: StoryProject

    var body: some View {
        ScrollView {
            CharacterRelationshipsPanel(character: character, project: project)
                .padding()
        }
        .navigationTitle("People")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterHistoryWorkspaceView: View {
    let character: CharacterProfile

    var body: some View {
        ScrollView {
            CharacterTimelinePanel(character: character)
                .padding()
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterVisualWorkspaceScreen: View {
    let character: CharacterProfile

    var body: some View {
        ScrollView {
            Group {
                if #available(iOS 18.1, *) {
                    CharacterVisualWorkspaceView(character: character)
                } else {
                    VisualFeatureUnavailableView()
                }
            }
            .padding()
        }
        .navigationTitle("Visual Studio")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterProfilePanel: View {
    let character: CharacterProfile

    private var populatedSections: [ProfileSection] {
        character.sortedSections.filter { section in
            section.fields.contains { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !character.summary.isEmpty {
                Text(character.summary)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if populatedSections.isEmpty && character.summary.isEmpty {
                ContentUnavailableView(
                    "Profile Is Still Empty",
                    systemImage: "person.text.rectangle",
                    description: Text("Use Edit Character to add identity, profile sections and facts.")
                )
            } else {
                ForEach(populatedSections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.headline)
                        ForEach(section.sortedFields) { field in
                            if !field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(field.label)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                    Text(field.value)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
