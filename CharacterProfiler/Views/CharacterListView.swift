// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData
import UIKit

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoryProject.updatedAt, order: .reverse) private var projects: [StoryProject]
    @Query private var characters: [CharacterProfile]
    @State private var showingNewProject = false

    var body: some View {
        NavigationStack {
            List {
                if projects.isEmpty {
                    ContentUnavailableView("No Stories", systemImage: "books.vertical", description: Text("Create a story project and start building its cast."))
                } else {
                    ForEach(projects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(project.title).font(.headline)
                                Label(project.genreDisplayName, systemImage: project.genre.icon)
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Text("\(project.characters.count) character\(project.characters.count == 1 ? "" : "s")")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteProjects)
                }
            }
            .navigationTitle("Character Profiler")
            .toolbar {
                Button { showingNewProject = true } label: { Label("New Story", systemImage: "plus") }
            }
            .sheet(isPresented: $showingNewProject) {
                NavigationStack { ProjectEditorView(project: nil) }
            }
            .task { migrateUnassignedCharacters() }
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets where projects.indices.contains(index) { modelContext.delete(projects[index]) }
        try? modelContext.save()
    }

    private func migrateUnassignedCharacters() {
        let unassigned = characters.filter { $0.project == nil }
        guard !unassigned.isEmpty else { return }
        let imported = projects.first(where: { $0.title == "Imported Characters" }) ?? StoryProject(title: "Imported Characters", genre: .other, customGenre: "Unassigned")
        if imported.modelContext == nil { modelContext.insert(imported) }
        for character in unassigned { character.project = imported }
        try? modelContext.save()
    }
}

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let project: StoryProject
    @State private var searchText = ""
    @State private var showingNewCharacter = false
    @State private var showingProjectEditor = false

    private var filteredCharacters: [CharacterProfile] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return project.sortedCharacters }
        return project.sortedCharacters.filter { character in
            character.name.localizedCaseInsensitiveContains(term) ||
            character.nickname.localizedCaseInsensitiveContains(term) ||
            character.storyRole.localizedCaseInsensitiveContains(term) ||
            character.summary.localizedCaseInsensitiveContains(term) ||
            character.sections.contains { section in
                section.title.localizedCaseInsensitiveContains(term) || section.fields.contains { $0.label.localizedCaseInsensitiveContains(term) || $0.value.localizedCaseInsensitiveContains(term) }
            }
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(project.genreDisplayName, systemImage: project.genre.icon).font(.subheadline.weight(.semibold))
                    if !project.premise.isEmpty { Text(project.premise).foregroundStyle(.secondary) }
                }.padding(.vertical, 4)
            }
            Section("Characters") {
                if project.characters.isEmpty {
                    ContentUnavailableView("No Characters", systemImage: "person.crop.circle.badge.plus", description: Text("Add the first character to this story."))
                } else {
                    ForEach(filteredCharacters) { character in
                        NavigationLink { CharacterDetailView(character: character) } label: { CharacterRow(character: character) }
                    }
                    .onDelete(perform: deleteCharacters)
                }
            }
        }
        .navigationTitle(project.title)
        .searchable(text: $searchText, prompt: "Search characters")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingProjectEditor = true } label: { Label("Edit Story", systemImage: "pencil") }
                Button { showingNewCharacter = true } label: { Label("New Character", systemImage: "person.badge.plus") }
            }
        }
        .sheet(isPresented: $showingNewCharacter) { NavigationStack { CharacterEditorView(project: project, character: nil) } }
        .sheet(isPresented: $showingProjectEditor) { NavigationStack { ProjectEditorView(project: project) } }
    }

    private func deleteCharacters(at offsets: IndexSet) {
        let visible = filteredCharacters
        for index in offsets where visible.indices.contains(index) { modelContext.delete(visible[index]) }
        project.updatedAt = .now
        try? modelContext.save()
    }
}

private struct CharacterRow: View {
    let character: CharacterProfile
    var body: some View {
        HStack(spacing: 12) {
            CharacterPortraitView(character: character, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(character.displayName).font(.headline)
                if !character.storyRole.isEmpty { Text(character.storyRole).font(.subheadline).foregroundStyle(.secondary) }
                else if !character.summary.isEmpty { Text(character.summary).font(.subheadline).foregroundStyle(.secondary).lineLimit(1) }
                ProgressView(value: character.completionScore)
            }
        }.padding(.vertical, 3)
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
                Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().foregroundStyle(.secondary).padding(size * 0.08)
            }
        }
        .frame(width: size, height: size)
        .background(.thinMaterial)
        .clipShape(Circle())
        .overlay(Circle().stroke(.quaternary, lineWidth: 1))
    }
}
