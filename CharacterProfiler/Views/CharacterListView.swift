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

        let imported = projects.first(where: {
            $0.title == "Imported Characters" &&
            $0.genre == .other &&
            $0.customGenre == "Unassigned"
        }) ?? StoryProject(title: "Imported Characters", genre: .other, customGenre: "Unassigned")

        if imported.modelContext == nil { modelContext.insert(imported) }
        for character in unassigned {
            character.project = imported
            if !imported.characters.contains(where: { $0.id == character.id }) {
                imported.characters.append(character)
            }
        }
        imported.updatedAt = .now
        try modelContext.saveOrRollback()
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
    @State private var isRestoringBackup = false

    private var totalCharacters: Int { projects.reduce(0) { $0 + $1.characters.count } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StoryLibrarySummary(
                        storyCount: projects.count,
                        characterCount: totalCharacters
                    )
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    if projects.isEmpty {
                        VStack(spacing: 14) {
                            CharacterProfilerIconTile(
                                systemImage: "books.vertical.fill",
                                accent: CharacterProfilerTheme.indigo,
                                size: 58
                            )
                            Text("Start Your First Story")
                                .font(.title3.bold())
                            Text("Create a story project, then build its cast, relationships, history and visual references in one place.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button {
                                showingNewProject = true
                            } label: {
                                Label("Create First Story", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .padding(.horizontal, 18)
                        .background {
                            CharacterProfilerCardSurface(
                                accent: CharacterProfilerTheme.indigo,
                                prominent: true
                            )
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(projects) { project in
                            NavigationLink {
                                ProjectDetailView(project: project)
                            } label: {
                                StoryLibraryRow(project: project)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: stageProjectDeletion)
                    }
                } header: {
                    CharacterProfilerSectionHeader(
                        title: "Your Stories",
                        systemImage: "books.vertical"
                    )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background { CharacterProfilerBackdrop() }
            .navigationTitle("Character Profiler")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button { showingImporter = true } label: {
                            Label("Restore Backup", systemImage: "square.and.arrow.down")
                        }
                        .disabled(isRestoringBackup)
                    } label: {
                        if isRestoringBackup {
                            ProgressView().accessibilityLabel("Restoring backup")
                        } else {
                            Label("Library Actions", systemImage: "ellipsis.circle")
                        }
                    }

                    Button { showingNewProject = true } label: {
                        Label("New Story", systemImage: "plus")
                    }
                    .disabled(isRestoringBackup)
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
                    restoreProject(from: url)
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
            try modelContext.saveOrRollback()
            projectsPendingDeletion = []
        } catch {
            operationErrorMessage = error.localizedDescription
        }
    }

    private func restoreProject(from url: URL) {
        guard !isRestoringBackup else { return }
        isRestoringBackup = true

        Task {
            do {
                let archive = try await Task.detached(priority: .userInitiated) {
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    return try ProjectArchive.safelyDecode(contentsOf: url)
                }.value

                _ = try archive.restore(in: modelContext)
                isRestoringBackup = false
            } catch {
                importErrorMessage = error.localizedDescription
                isRestoringBackup = false
            }
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let project: StoryProject
    @State private var searchText = ""
    @State private var showingNewCharacter = false
    @State private var showingProjectEditor = false
    @State private var showingExporter = false
    @State private var showingStoryDeletionConfirmation = false
    @State private var exportDocument: ProjectArchiveDocument?
    @State private var exportErrorMessage: String?
    @State private var isPreparingExport = false
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
                StoryHeroCard(
                    project: project,
                    characterCount: project.characters.count,
                    relationshipCount: relationshipCount,
                    historyCount: historyCount,
                    guideAnswerCount: guideAnswerCount,
                    averageDevelopment: averageDevelopment
                )
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                if project.characters.isEmpty {
                    VStack(spacing: 14) {
                        CharacterProfilerIconTile(
                            systemImage: "person.crop.circle.badge.plus",
                            accent: CharacterProfilerTheme.violet,
                            size: 56
                        )
                        Text("Build the Cast")
                            .font(.title3.bold())
                        Text("Add the first character, then open their workspace to develop profile, Guide answers, relationships, history and visuals.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            showingNewCharacter = true
                        } label: {
                            Label("Create First Character", systemImage: "person.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .padding(.horizontal, 18)
                    .background {
                        CharacterProfilerCardSurface(
                            accent: CharacterProfilerTheme.violet,
                            prominent: true
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else if filteredCharacters.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(filteredCharacters) { character in
                        NavigationLink {
                            CharacterDetailView(character: character)
                        } label: {
                            CharacterRow(character: character)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: stageCharacterDeletion)
                }
            } header: {
                HStack {
                    CharacterProfilerSectionHeader(
                        title: "Characters",
                        systemImage: "person.2"
                    )
                    Spacer()
                    if !project.characters.isEmpty {
                        Button {
                            showingNewCharacter = true
                        } label: {
                            Label("Add", systemImage: "plus")
                                .labelStyle(.titleAndIcon)
                        }
                        .textCase(nil)
                    }
                }
            } footer: {
                if project.characters.count > 20 {
                    Text("Search includes names, nicknames, roles, summaries, profile fields, relationship names and relationship notes.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background { CharacterProfilerBackdrop() }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.large)
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
                        if isPreparingExport {
                            Label("Preparing Backup", systemImage: "hourglass")
                        } else {
                            Label("Export Backup", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(isPreparingExport)
                    Divider()
                    Button(role: .destructive) {
                        showingStoryDeletionConfirmation = true
                    } label: {
                        Label("Delete Story", systemImage: "trash")
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
        .alert("Delete Story?", isPresented: $showingStoryDeletionConfirmation) {
            Button("Delete Story Permanently", role: .destructive) { confirmStoryDeletion() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(storyDeletionMessage)
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
        guard !isPreparingExport else { return }
        isPreparingExport = true

        let archive = ProjectArchive(project: project)
        Task {
            do {
                let data = try await Task.detached(priority: .userInitiated) {
                    try archive.safelyEncodedData()
                }.value
                exportDocument = ProjectArchiveDocument(data: data)
                showingExporter = true
            } catch {
                exportErrorMessage = error.localizedDescription
            }
            isPreparingExport = false
        }
    }

    private var storyDeletionMessage: String {
        let characterCount = project.characters.count
        return "This permanently deletes \(project.title), \(characterCount) character\(characterCount == 1 ? "" : "s"), \(relationshipCount) relationship\(relationshipCount == 1 ? "" : "s"), and all profile, history, Guide and visual data inside it. Export a backup first if you may need this work again."
    }

    private func confirmStoryDeletion() {
        modelContext.delete(project)
        do {
            try modelContext.saveOrRollback()
            dismiss()
        } catch {
            operationErrorMessage = error.localizedDescription
        }
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
            try modelContext.saveOrRollback()
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

private struct StoryLibrarySummary: View {
    let storyCount: Int
    let characterCount: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(CharacterProfilerTheme.heroGradient)

            Image(systemName: "book.pages.fill")
                .font(.system(size: 112, weight: .bold))
                .foregroundStyle(.white.opacity(0.08))
                .rotationEffect(.degrees(-8))
                .offset(x: 24, y: -16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 16) {
                Label("STORY DEVELOPMENT STUDIO", systemImage: "sparkles")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CharacterProfilerTheme.gold)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Story Library")
                        .font(.title.bold())
                    Text(storyCount == 0
                         ? "A focused home for stories, characters and the worlds around them."
                         : "Every story, character and creative thread in one place.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                }

                HStack(spacing: 10) {
                    LibraryMetric(value: storyCount, label: storyCount == 1 ? "Story" : "Stories", icon: "books.vertical")
                    LibraryMetric(value: characterCount, label: characterCount == 1 ? "Character" : "Characters", icon: "person.2")
                }
            }
            .foregroundStyle(.white)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shadow(color: CharacterProfilerTheme.ink.opacity(0.24), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("story-library-hero")
    }
}

private struct LibraryMetric: View {
    let value: Int
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .accessibilityHidden(true)
            Text("\(value)")
                .font(.subheadline.monospacedDigit().weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.white.opacity(0.11), in: Capsule())
    }
}

private struct StoryLibraryRow: View {
    let project: StoryProject

    private var averageDevelopment: Int {
        guard !project.characters.isEmpty else { return 0 }
        let average = project.characters.reduce(0.0) { $0 + $1.completionScore } / Double(project.characters.count)
        return Int((average * 100).rounded())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            CharacterProfilerIconTile(
                systemImage: project.genre.icon,
                accent: CharacterProfilerTheme.indigo
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(project.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(project.genreDisplayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                if !project.premise.isEmpty {
                    Text(project.premise)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 10) {
                    Label("\(project.characters.count)", systemImage: "person.2")
                    if !project.characters.isEmpty {
                        Label("\(averageDevelopment)%", systemImage: "chart.bar")
                    }
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(CharacterProfilerTheme.indigo)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { CharacterProfilerCardSurface(accent: CharacterProfilerTheme.indigo) }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct StoryHeroCard: View {
    let project: StoryProject
    let characterCount: Int
    let relationshipCount: Int
    let historyCount: Int
    let guideAnswerCount: Int
    let averageDevelopment: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 13) {
                CharacterProfilerIconTile(
                    systemImage: project.genre.icon,
                    accent: CharacterProfilerTheme.gold,
                    size: 52
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.genreDisplayName.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(0.7)
                        .foregroundStyle(CharacterProfilerTheme.gold)
                    Text(characterCount == 0 ? "Ready to build your cast" : "\(characterCount) character\(characterCount == 1 ? "" : "s") in this story")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }

            if !project.premise.isEmpty {
                Text(project.premise)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.80))
            }

            ProjectOverviewGrid(
                characterCount: characterCount,
                relationshipCount: relationshipCount,
                historyCount: historyCount,
                guideAnswerCount: guideAnswerCount,
                averageDevelopment: averageDevelopment
            )
        }
        .padding(20)
        .background(CharacterProfilerTheme.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
        .shadow(color: CharacterProfilerTheme.ink.opacity(0.24), radius: 18, y: 10)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story-workspace-hero")
    }
}

private struct ProjectOverviewGrid: View {
    let characterCount: Int
    let relationshipCount: Int
    let historyCount: Int
    let guideAnswerCount: Int
    let averageDevelopment: Int

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ProjectMetric(value: "\(characterCount)", label: "Characters", icon: "person.2", accent: CharacterProfilerTheme.violet)
            ProjectMetric(value: "\(relationshipCount)", label: "Relationships", icon: "point.3.connected.trianglepath.dotted", accent: CharacterProfilerTheme.rose)
            ProjectMetric(value: "\(historyCount)", label: "Life events", icon: "clock.arrow.circlepath", accent: CharacterProfilerTheme.teal)
            ProjectMetric(value: "\(guideAnswerCount)", label: "Guide answers", icon: "sparkles", accent: CharacterProfilerTheme.gold)
            ProjectMetric(value: "\(averageDevelopment)%", label: "Development", icon: "chart.bar", accent: CharacterProfilerTheme.indigo)
        }
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
    let accent: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 18)
                .foregroundStyle(accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.66))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct CharacterRow: View {
    let character: CharacterProfile

    var body: some View {
        HStack(spacing: 13) {
            CharacterPortraitView(character: character, size: 54)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(character.displayName)
                        .font(.headline)
                    Spacer()
                    Text("\(Int(character.completionScore * 100))%")
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundStyle(CharacterProfilerTheme.violet)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CharacterProfilerTheme.violet.opacity(0.11), in: Capsule())
                }
                if !character.storyRole.isEmpty {
                    Text(character.storyRole)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if !character.summary.isEmpty {
                    Text(character.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                ProgressView(value: character.completionScore)
                    .tint(CharacterProfilerTheme.violet)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { CharacterProfilerCardSurface(accent: CharacterProfilerTheme.violet) }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        .overlay(
            Circle().stroke(
                LinearGradient(
                    colors: [CharacterProfilerTheme.gold, CharacterProfilerTheme.violet],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: max(1.5, size * 0.025)
            )
        )
        .shadow(color: CharacterProfilerTheme.violet.opacity(0.16), radius: size * 0.08, y: size * 0.04)
        .accessibilityHidden(true)
    }
}
