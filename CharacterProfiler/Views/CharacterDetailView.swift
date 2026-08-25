// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI

private struct CharacterDeletionActionKey: EnvironmentKey {
    static let defaultValue: (CharacterProfile) -> Void = { _ in }
}

extension EnvironmentValues {
    var characterDeletionAction: (CharacterProfile) -> Void {
        get { self[CharacterDeletionActionKey.self] }
        set { self[CharacterDeletionActionKey.self] = newValue }
    }
}

/// Character home screen. Heavy workspaces are intentionally separate navigation destinations so
/// the iPhone experience stays readable and each task gets enough room to breathe.
struct CharacterDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.characterDeletionAction) private var deleteCharacter
    let character: CharacterProfile
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteCharacterAfterDismiss = false

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
                        .background { CharacterProfilerCardSurface(accent: CharacterProfilerTheme.gold) }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Character Workspace", systemImage: "square.grid.2x2.fill")
                        .font(.title3.bold())
                        .foregroundStyle(CharacterProfilerTheme.indigo)
                    Text("Choose the part of this character you want to develop.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    CharacterProfileWorkspaceView(character: character)
                } label: {
                    CharacterWorkspaceCard(
                        title: "Profile",
                        subtitle: profileFactCount == 0 ? "Build identity, personality and custom facts" : "Review and edit \(profileFactCount) saved fact\(profileFactCount == 1 ? "" : "s")",
                        systemImage: "person.text.rectangle",
                        badge: profileFactCount == 0 ? "Start" : "\(profileFactCount)",
                        accent: CharacterProfilerTheme.indigo
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
                            badge: guideAnswerCount == 0 ? "Explore" : "\(guideAnswerCount)",
                            accent: CharacterProfilerTheme.gold
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
                            badge: relationshipCount == 0 ? "Add" : "\(relationshipCount)",
                            accent: CharacterProfilerTheme.rose
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("workspace-relationships")
                } else {
                    CharacterWorkspaceCard(
                        title: "Character Guide",
                        subtitle: "Assign this character to a story to use the Guide",
                        systemImage: "sparkles",
                        badge: "Unavailable",
                        accent: CharacterProfilerTheme.gold
                    )
                    CharacterWorkspaceCard(
                        title: "People & Relationships",
                        subtitle: "Assign this character to a story to link people",
                        systemImage: "person.2",
                        badge: "Unavailable",
                        accent: CharacterProfilerTheme.rose
                    )
                }

                NavigationLink {
                    CharacterHistoryWorkspaceView(character: character)
                } label: {
                    CharacterWorkspaceCard(
                        title: "History",
                        subtitle: historyCount == 0 ? "Record the events that shaped this character" : "\(historyCount) life event\(historyCount == 1 ? "" : "s") in chronological order",
                        systemImage: "clock.arrow.circlepath",
                        badge: historyCount == 0 ? "Add" : "\(historyCount)",
                        accent: CharacterProfilerTheme.teal
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
                        subtitle: visualAssetCount == 0 ? "Develop 2D appearance or reconstruct a 3D head" : "Work with \(visualAssetCount) saved visual asset\(visualAssetCount == 1 ? "" : "s") and optional 3D reconstruction",
                        systemImage: "person.crop.rectangle.stack",
                        badge: visualAssetCount == 0 ? "Open" : "\(visualAssetCount)",
                        accent: CharacterProfilerTheme.violet
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workspace-visual")
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background { CharacterProfilerBackdrop() }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if character.project != nil {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingEditor = true } label: {
                        Label("Edit Character", systemImage: "pencil")
                    }

                    Menu {
                        Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                            Label("Delete Character", systemImage: "trash")
                        }
                    } label: {
                        Label("Character Actions", systemImage: "ellipsis.circle")
                    }
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
            Button("Delete Character Permanently", role: .destructive) { stageCharacterDeletion() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(characterDeletionMessage)
        }
        .onDisappear {
            if deleteCharacterAfterDismiss {
                // Cascade deletion invalidates the character's SwiftData children immediately.
                // Delete only after this destination can no longer render those child models.
                deleteCharacter(character)
            }
        }
    }

    private var characterDeletionMessage: String {
        let answerCount = guideAnswerCount
        return "This permanently deletes \(character.displayName) and removes \(relationshipCount) linked relationship\(relationshipCount == 1 ? "" : "s"), \(historyCount) history entr\(historyCount == 1 ? "y" : "ies"), \(answerCount) Guide answer\(answerCount == 1 ? "" : "s"), and \(visualAssetCount) visual asset\(visualAssetCount == 1 ? "" : "s"). Export the story backup first if you may need this character again."
    }

    private func stageCharacterDeletion() {
        deleteCharacterAfterDismiss = true
        dismiss()
    }
}

private struct CharacterHeader: View {
    let character: CharacterProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("CHARACTER DOSSIER", systemImage: "person.text.rectangle.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(CharacterProfilerTheme.gold)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 16) {
                    CharacterPortraitView(character: character, size: 96)
                    headerDetails
                }
                VStack(alignment: .leading, spacing: 14) {
                    CharacterPortraitView(character: character, size: 88)
                    headerDetails
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(CharacterProfilerTheme.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
        .shadow(color: CharacterProfilerTheme.ink.opacity(0.24), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("character-dossier-hero")
    }

    private var headerDetails: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(character.displayName)
                .font(.title2.bold())
                .lineLimit(2)
            if !character.storyRole.isEmpty {
                Text(character.storyRole)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.76))
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { identityDetails }
                VStack(alignment: .leading, spacing: 4) { identityDetails }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.72))
            ProgressView(value: character.completionScore)
                .tint(CharacterProfilerTheme.gold)
                .accessibilityLabel("Character development")
                .accessibilityValue("\(Int(character.completionScore * 100)) percent")
            Text("\(Int(character.completionScore * 100))% developed")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CharacterProfilerTheme.gold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var identityDetails: some View {
        if !character.ageText.isEmpty {
            Label(character.ageText, systemImage: "birthday.cake")
        }
        if !character.pronouns.isEmpty { Text(character.pronouns) }
    }
}

private struct CharacterWorkspaceCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let badge: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            CharacterProfilerIconTile(systemImage: systemImage, accent: accent, size: 46)

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
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.11), in: Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { CharacterProfilerCardSurface(accent: accent) }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CharacterProfileWorkspaceView: View {
    let character: CharacterProfile
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            CharacterProfilePanel(character: character)
                .padding()
        }
        .background { CharacterProfilerBackdrop() }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if character.project != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit", systemImage: "pencil") { showingEditor = true }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let project = character.project {
                NavigationStack { CharacterEditorView(project: project, character: character) }
            }
        }
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
        .background { CharacterProfilerBackdrop() }
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
        .background { CharacterProfilerBackdrop() }
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
        .background { CharacterProfilerBackdrop() }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum VisualStudioMode: String, CaseIterable, Identifiable {
    case twoD = "2D Appearance"
    case threeD = "3D Reconstruction"

    var id: Self { self }
}

private struct CharacterVisualWorkspaceScreen: View {
    let character: CharacterProfile
    @State private var mode: VisualStudioMode = .twoD

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose how you want to inspect this character's appearance.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("Visual mode", selection: $mode) {
                        ForEach(VisualStudioMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("visual-mode-picker")
                }

                switch mode {
                case .twoD:
                    Group {
                        if #available(iOS 18.1, *) {
                            CharacterVisualWorkspaceView(character: character)
                        } else {
                            VisualFeatureUnavailableView()
                        }
                    }
                case .threeD:
                    Character3DHeadWorkspaceView(character: character)
                }
            }
            .padding()
        }
        .background { CharacterProfilerBackdrop() }
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
                    description: Text("Use Edit to add identity, profile sections and facts.")
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
                    .background { CharacterProfilerCardSurface(accent: CharacterProfilerTheme.indigo) }
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
