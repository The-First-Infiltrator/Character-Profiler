// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData
import PhotosUI

struct ProjectEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let project: StoryProject?
    @State private var draft: ProjectDraft

    init(project: StoryProject?) {
        self.project = project
        _draft = State(initialValue: project.map(ProjectDraft.init) ?? ProjectDraft())
    }

    var body: some View {
        Form {
            Section("Story") {
                TextField("Project title", text: $draft.title)
                Picker("Genre", selection: $draft.genre) {
                    ForEach(StoryGenre.allCases) { genre in Text(genre.displayName).tag(genre) }
                }
                if draft.genre == .other { TextField("Custom genre", text: $draft.customGenre) }
                TextField("Premise or story summary", text: $draft.premise, axis: .vertical).lineLimit(3...8)
            }
            Section { Text("The genre controls the development questions suggested to authors. You can change it later without losing character data.").font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle(project == nil ? "New Story" : "Edit Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    _ = draft.save(to: project, in: modelContext)
                    try? modelContext.save(); dismiss()
                }.disabled(!draft.isValid)
            }
        }
    }
}

struct CharacterEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let project: StoryProject
    let character: CharacterProfile?
    @State private var draft: ProfileDraft
    @State private var photoItem: PhotosPickerItem?

    init(project: StoryProject, character: CharacterProfile?) {
        self.project = project
        self.character = character
        _draft = State(initialValue: character.map(ProfileDraft.init) ?? ProfileDraft())
    }

    var body: some View {
        Form {
            Section("Character") {
                HStack(spacing: 16) {
                    portraitPreview
                    PhotosPicker(selection: $photoItem, matching: .images) { Label("Choose Portrait", systemImage: "photo") }
                }
                TextField("Name", text: $draft.name)
                TextField("Nickname", text: $draft.nickname)
                TextField("Age", text: $draft.ageText)
                TextField("Pronouns", text: $draft.pronouns)
                TextField("Story role", text: $draft.storyRole)
                TextField("Short summary", text: $draft.summary, axis: .vertical).lineLimit(2...6)
            }

            ForEach($draft.sections) { $section in
                Section {
                    TextField("Section name", text: $section.title).font(.headline)
                    ForEach($section.fields) { $field in
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Field name", text: $field.label).font(.caption).foregroundStyle(.secondary)
                            TextField("Value", text: $field.value, axis: .vertical).lineLimit(1...5)
                        }
                    }
                    .onDelete { section.fields.remove(atOffsets: $0) }
                    Button("Add Field") { section.fields.append(FieldDraft(label: "New Field", value: "")) }
                } header: { Text(section.title.isEmpty ? "Section" : section.title) }
            }
            .onDelete { draft.sections.remove(atOffsets: $0) }

            Section { Button("Add Section") { draft.addSection() } }
        }
        .navigationTitle(character == nil ? "New Character" : "Edit Character")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    _ = draft.save(to: character, project: project, in: modelContext)
                    try? modelContext.save(); dismiss()
                }.disabled(!draft.isValid)
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let normalised = CharacterImageProcessor.normalisedJPEGData(from: data) {
                    await MainActor.run { draft.profileImageData = normalised }
                }
            }
        }
    }

    @ViewBuilder private var portraitPreview: some View {
        if let data = draft.profileImageData, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill().frame(width: 72, height: 72).clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().foregroundStyle(.secondary).frame(width: 72, height: 72)
        }
    }
}
