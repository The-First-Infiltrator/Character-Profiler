// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData
import PhotosUI

struct ProjectEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let project: StoryProject?
    @State private var draft: ProjectDraft
    @State private var saveErrorMessage: String?

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
            Section {
                Text("The genre controls the development questions suggested to authors. You can change it later without losing character data.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(project == nil ? "New Story" : "Edit Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveProject() }.disabled(!draft.isValid)
            }
        }
        .alert("Story Could Not Be Saved", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "Unknown save error.")
        }
    }

    private func saveProject() {
        _ = draft.save(to: project, in: modelContext)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
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
    @State private var errorMessage: String?

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
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Choose Portrait", systemImage: "photo")
                    }
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
                } header: {
                    Text(section.title.isEmpty ? "Section" : section.title)
                }
            }
            .onDelete { draft.sections.remove(atOffsets: $0) }

            Section { Button("Add Section") { draft.addSection() } }
        }
        .navigationTitle(character == nil ? "New Character" : "Edit Character")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveCharacter() }.disabled(!draft.isValid)
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            importPortrait(item)
        }
        .alert("Character Change Could Not Be Completed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error.")
        }
    }

    private func saveCharacter() {
        _ = draft.save(to: character, project: project, in: modelContext)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importPortrait(_ item: PhotosPickerItem) {
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    await MainActor.run {
                        errorMessage = "The selected photo could not be read. Choose another image and try again."
                        photoItem = nil
                    }
                    return
                }
                guard let normalised = CharacterImageProcessor.normalisedJPEGData(from: data) else {
                    await MainActor.run {
                        errorMessage = "The selected photo could not be converted into a usable portrait. Choose another image and try again."
                        photoItem = nil
                    }
                    return
                }
                await MainActor.run {
                    draft.profileImageData = normalised
                    photoItem = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    photoItem = nil
                }
            }
        }
    }

    @ViewBuilder
    private var portraitPreview: some View {
        if let data = draft.profileImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .accessibilityLabel("Current character portrait")
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .frame(width: 72, height: 72)
                .accessibilityLabel("No character portrait selected")
        }
    }
}
