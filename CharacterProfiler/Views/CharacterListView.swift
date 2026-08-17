// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers

enum LegacyDataMigration {
    @MainActor
    @discardableResult
    static func assignUnassignedCharacters(
        _ characters: [CharacterProfile],
        projects: [StoryProject],
        in modelContext: ModelContext
    ) throws -> StoryProject? {
        let unassigned = characters.filter { $0.project == nil }
        guard !unassigned.isEmpty else { return nil }

        let imported = projects.first(where: { $0.title == "Imported Characters" })
            ?? StoryProject(title: "Imported Characters", genre: .other, customGenre: "Unassigned")

        if imported.modelContext == nil { modelContext.insert(imported) }
        for character in unassigned {
            character.project = imported
            if !imported.characters.contains(where: { $0.id == character.id }) {
                imported.characters.append(character)
            }
        }
        imported.updatedAt = .now
        try modelContext.save()
        return imported
    }
}

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoryProject.updatedAt, order: .reverse) private var projects: [StoryProject]
    @Query private var characters: [CharacterProfile]
    @State private var showingNewProject = false
    @State private var showingImporter = false
    @State private var importErrorMessage: String?
    @State private var operationErrorMessage: String?
    @State private var projectsPendingDeletion: [StoryProject] = []

    var body: some View {
        NavigationStack {
            List {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "No Stories",
                        systemImage: "books.vertical",
                        description: Text("Create a story project or restore one from a Character Profiler backup.")
                    )
                } else {
                    ForEach(projects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(project.title).font(.headline)
                                Label(project.genreDisplayName, systemImage: project.genre.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(project.characters.count) character\(project.characters.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .onDelete(perform: stageProjectDeletion)
                }
            }
            .navigationTitle("Character Profiler")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingImporter = true } label: {
                        Label("Restore Backup", systemImage: "square.and.arrow.down")
                    }
                    Button { showingNewProject = true } label: {
                        Label("New Story", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NavigationStack { ProjectEditorView(project: nil) }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    Task { @MainActor in restoreProject(from: url) }
                case .failure(let error):
                    importErrorMessage = error.localizedDescription
                }
            }
            .alert("Backup Could Not Be Restored", isPresented: Binding(
                get: { importErrorMessage != nil },
                set: { if !$0 { importErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { importErrorMessage = nil }
            } message: {
                Text(importErrorMessage ?? "Unknown import error.")
            }
            .alert("Story Library Change Could Not Be Saved", isPresented: Binding(
                get: { operationErrorMessage != nil },
                set: { if !$0 { operationErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { operationErrorMessage = nil }
            } message: {
                Text(operationErrorMessage ?? "Unknown save error.")
            }
            .confirmationDialog(
                "Delete Story?",
                isPresented: Binding(
                    get: { !projectsPendingDeletion.isEmpty },
                    set: { if !$0 { projectsPendingDeletion = [] } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Permanently", role: .destructive) { confirmProjectDeletion() }
                Button("Cancel", role: .cancel) { projectsPendingDeletion = [] }
            } message: {
                Text(projectDeletionMessage)
            }
            .task { migrateUnassignedCharacters() }
        }
    }

    private func stageProjectDeletion(at offsets: IndexSet) {
        projectsPendingDeletion = offsets.compactMap { projects.indices.contains($0) ? projects[$0] : nil }
    }

    private var projectDeletionMessage: String {
        let selected = projectsPendingDeletion
        let characterCount = selected.reduce(0) { $0 + $1.characters.count }
        let relationshipCount = Set(selected.flatMap { project in
            project.characters.flatMap { $0.allRelationships.map(\.id) }
        }).count
        let storyWord = selected.count == 1 ? "story" : "stories"
        return "This permanently deletes \(selected.count) \(storyWord), \(characterCount) character\(characterCount == 1 ? "" : "s"), \(relationshipCount) relationship\(relationshipCount == 1 ? "" : "s"), and all profile, history, Guide and visual data inside them. Export a backup first if you may need this work again."
    }

    private func confirmProjectDeletion() {
        let selected = projectsPendingDeletion
        for project in selected { modelContext.delete(project) }
        do {
            try modelContext.save()
            projectsPendingDeletion = []
        } catch {
            operationErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func restoreProject(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let archive = try ProjectArchive.decode(data)
            _ = try archive.restore(in: modelContext)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func migrateUnassignedCharacters() {
        do {
            _ = try LegacyDataMigration.assignUnassignedCharacters(characters, projects: projects, in: modelContext)
        } catch {
            operationErrorMessage = "Older unassigned character records could not be migrated into Imported Characters. \(error.localizedDescription)"
        }
    }
}

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let project: StoryProject
    @State private var searchText = ""
    @State private var showingNewCharacter = false
    @State private var showingProjectEditor = false
    @State private var showingExporter = false
    @State private var exportDocument: ProjectArchiveDocument?
    @State private var exportErrorMessage: String?
    @State private var operationErrorMessage: String?
    @State private var charactersPendingDeletion: [CharacterProfile] = []

    private var filteredCharacters: [CharacterProfile] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return project.sortedCharacters }
        return project.sortedCharacters.filter { character in
            CharacterSearch.matches(character, term: term)
        }
    }

    private var relationshipCount: Int {
        Set(project.characters.flatMap { $0.allRelationships.map(\.id) }).count
    }

    private var historyCount: Int {
        project.characters.reduce(0) { $0 + $1.lifeEvents.count }
    }

    private var guideAnswerCount: Int {
        project.characters.reduce(0) { total, character in
            total + character.promptResponses.filter {
                !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.count
        }
    }

    private var averageDevelopment: Int {
        guard !project.characters.isEmpty else { return 0 }
        let average = project.characters.reduce(0.0) { $0 + $1.completionScore } / Double(project.characters.count)
        return Int((average * 100).rounded())
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label(project.genreDisplayName, systemImage: project.genre.icon)
                        .font(.subheadline.weight(.semibold))
                    if !project.premise.isEmpty { Text(project.premise).foregroundStyle(.secondary) }
                    ProjectOverviewGrid(
                        characterCount: project.characters.count,
                        relationshipCount: relationshipCount,
                        historyCount: historyCount,
                        guideAnswerCount: guideAnswerCount,
                        averageDevelopment: averageDevelopment
                    )
                }
                .padding(.vertical, 4)
            }

            Section {
                if project.characters.isEmpty {
                    ContentUnavailableView(
                        "No Characters",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Add the first character to this story.")
                    )
                } else if filteredCharacters.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(filteredCharacters) { character in
                        NavigationLink {
                            CharacterDetailView(character: character)
                        } label: {
                            CharacterRow(character: character)
                        }
                    }
                    .onDelete(perform: stageCharacterDeletion)
                }
            } header: {
                HStack {
                    Text("Characters")
                    Spacer()
                    if project.characters.count > 20 || !searchText.isEmpty {
                        Text("\(filteredCharacters.count) of \(project.characters.count)")
                            .monospacedDigit()
                    }
                }
            } footer: {
                if project.characters.count > 20 {
                    Text("Search includes names, nicknames, roles, summaries, profile fields, relationship names and relationship notes.")
                }
            }
        }
        .navigationTitle(project.title)
        .searchable(text: $searchText, prompt: "Search characters")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingNewCharacter = true } label: {
                    Label("New Character", systemImage: "person.badge.plus")
                }
                Menu {
                    Button { showingProjectEditor = true } label: {
                        Label("Edit Story", systemImage: "pencil")
                    }
                    Button { prepareExport() } label: {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("Story Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingNewCharacter) {
            NavigationStack { CharacterEditorView(project: project, character: nil) }
        }
        .sheet(isPresented: $showingProjectEditor) {
            NavigationStack { ProjectEditorView(project: project) }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: ProjectArchive.suggestedFilename(for: project)
        ) { result in
            if case .failure(let error) = result { exportErrorMessage = error.localizedDescription }
            exportDocument = nil
        }
        .alert("Backup Could Not Be Exported", isPresented: Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { exportErrorMessage = nil }
        } message: {
            Text(exportErrorMessage ?? "Unknown export error.")
        }
        .alert("Story Change Could Not Be Saved", isPresented: Binding(
            get: { operationErrorMessage != nil },
            set: { if !$0 { operationErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { operationErrorMessage = nil }
        } message: {
            Text(operationErrorMessage ?? "Unknown save error.")
        }
        .confirmationDialog(
            "Delete Character?",
            isPresented: Binding(
                get: { !charactersPendingDeletion.isEmpty },
                set: { if !$0 { charactersPendingDeletion = [] } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) { confirmCharacterDeletion() }
            Button("Cancel", role: .cancel) { charactersPendingDeletion = [] }
        } message: {
            Text(characterDeletionMessage)
        }
    }

    private func prepareExport() {
        exportDocument = ProjectArchiveDocument(archive: ProjectArchive(project: project))
        showingExporter = true
    }

    private func stageCharacterDeletion(at offsets: IndexSet) {
        let visible = filteredCharacters
        charactersPendingDeletion = offsets.compactMap { visible.indices.contains($0) ? visible[$0] : nil }
    }

    private var characterDeletionMessage: String {
        let selected = charactersPendingDeletion
        let relationshipCount = Set(selected.flatMap { $0.allRelationships.map(\.id) }).count
        let historyCount = selected.reduce(0) { $0 + $1.lifeEvents.count }
        let answerCount = selected.reduce(0) { total, character in
            total + character.promptResponses.filter {
                !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.count
        }
        let visualCount = selected.reduce(0) { total, character in
            total + character.referenceImages.count + character.visualFrames.count
                + (character.profileImageData == nil ? 0 : 1)
                + (character.generatedVisualData == nil ? 0 : 1)
        }
        let characterWord = selected.count == 1 ? "character" : "characters"
        return "This permanently deletes \(selected.count) \(characterWord) and removes \(relationshipCount) linked relationship\(relationshipCount == 1 ? "" : "s"), \(historyCount) history entr\(historyCount == 1 ? "y" : "ies"), \(answerCount) Guide answer\(answerCount == 1 ? "" : "s"), and \(visualCount) visual asset\(visualCount == 1 ? "" : "s"). Export a story backup first if you may need this character work again."
    }

    private func confirmCharacterDeletion() {
        let selected = charactersPendingDeletion
        for character in selected { modelContext.delete(character) }
        project.updatedAt = .now
        do {
            try modelContext.save()
            charactersPendingDeletion = []
        } catch {
            operationErrorMessage = error.localizedDescription
        }
    }
}

enum CharacterSearch {
    static func matches(_ character: CharacterProfile, term: String) -> Bool {
        let value = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return true }

        if character.name.localizedCaseInsensitiveContains(value) ||
            character.nickname.localizedCaseInsensitiveContains(value) ||
            character.storyRole.localizedCaseInsensitiveContains(value) ||
            character.summary.localizedCaseInsensitiveContains(value) {
            return true
        }

        if character.sections.contains(where: { section in
            section.title.localizedCaseInsensitiveContains(value) || section.fields.contains {
                $0.label.localizedCaseInsensitiveContains(value) ||
                $0.value.localizedCaseInsensitiveContains(value)
            }
        }) {
            return true
        }

        return character.allRelationships.contains { relationship in
            relationship.relatedCharacter(to: character)?.displayName.localizedCaseInsensitiveContains(value) == true ||
            relationship.notes.localizedCaseInsensitiveContains(value) ||
            relationship.kind(from: character).displayName.localizedCaseInsensitiveContains(value)
        }
    }
}

private struct ProjectOverviewGrid: View {
    let characterCount: Int
    let relationshipCount: Int
    let historyCount: Int
    let guideAnswerCount: Int
    let averageDevelopment: Int

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
            GridRow {
                ProjectMetric(value: "\(characterCount)", label: "Characters", icon: "person.2")
                ProjectMetric(value: "\(relationshipCount)", label: "Relationships", icon: "point.3.connected.trianglepath.dotted")
            }
            GridRow {
                ProjectMetric(value: "\(historyCount)", label: "Life events", icon: "clock.arrow.circlepath")
                ProjectMetric(value: "\(guideAnswerCount)", label: "Guide answers", icon: "sparkles")
            }
            GridRow {
                ProjectMetric(value: "\(averageDevelopment)%", label: "Average development", icon: "chart.bar")
                Color.clear.frame(height: 1).accessibilityHidden(true)
            }
        }
        .font(.caption)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Project overview: \(characterCount) characters, \(relationshipCount) relationships, \(historyCount) life events, \(guideAnswerCount) Guide answers, \(averageDevelopment) percent average development"
        )
    }
}

private struct ProjectMetric: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon).frame(width: 18).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.subheadline.weight(.semibold))
                Text(label).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct CharacterRow: View {
    let character: CharacterProfile

    var body: some View {
        HStack(spacing: 12) {
            CharacterPortraitView(character: character, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(character.displayName).font(.headline)
                if !character.storyRole.isEmpty {
                    Text(character.storyRole).font(.subheadline).foregroundStyle(.secondary)
                } else if !character.summary.isEmpty {
                    Text(character.summary).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                }
                ProgressView(value: character.completionScore)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    private var rowAccessibilityLabel: String {
        var parts = [character.displayName]
        if !character.storyRole.isEmpty { parts.append(character.storyRole) }
        parts.append("\(Int(character.completionScore * 100)) percent developed")
        return parts.joined(separator: ", ")
    }
}

struct CharacterPortraitView: View {
    let character: CharacterProfile
    var size: CGFloat = 92

    var body: some View {
        Group {
            if let data = character.profileImageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(size * 0.08)
            }
        }
        .frame(width: size, height: size)
        .background(.thinMaterial)
        .clipShape(Circle())
        .overlay(Circle().stroke(.quaternary, lineWidth: 1))
        .accessibilityHidden(true)
    }
}
