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
            Section("Story Details") {
                TextField("Story title", text: $draft.title)
                    .textInputAutocapitalization(.words)
                Picker("Genre", selection: $draft.genre) {
                    ForEach(StoryGenre.allCases) { genre in
                        Label(genre.displayName, systemImage: genre.icon).tag(genre)
                    }
                }
                if draft.genre == .other {
                    TextField("Custom genre", text: $draft.customGenre)
                }
            }

            Section("Premise") {
                TextField(
                    "What is this story about?",
                    text: $draft.premise,
                    axis: .vertical
                )
                .lineLimit(4...10)
            } footer: {
                Text("The premise appears at the top of the story workspace. Genre helps Character Guide choose useful development questions and can be changed later without losing character data.")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(project == nil ? "New Story" : "Edit Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveProject() }
                    .fontWeight(.semibold)
                    .disabled(!draft.isValid)
            }
        }
        .alert("Story Change Could Not Be Completed", isPresented: Binding(
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
            try modelContext.saveOrRollback()
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
            portraitSection

            Section("Identity") {
                TextField("Name", text: $draft.name)
                    .textInputAutocapitalization(.words)
                TextField("Nickname", text: $draft.nickname)
                    .textInputAutocapitalization(.words)
                HStack {
                    TextField("Age", text: $draft.ageText)
                        .frame(maxWidth: .infinity)
                    Divider()
                    TextField("Pronouns", text: $draft.pronouns)
                        .frame(maxWidth: .infinity)
                }
            }

            Section("Story") {
                TextField("Role in the story", text: $draft.storyRole)
                    .textInputAutocapitalization(.sentences)
                TextField(
                    "Short character summary",
                    text: $draft.summary,
                    axis: .vertical
                )
                .lineLimit(3...8)
            } footer: {
                Text("Keep the summary short enough to scan quickly. Detailed facts belong in Profile Details below.")
            }

            Section {
                if draft.sections.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("No profile sections yet", systemImage: "square.stack.3d.up")
                            .font(.headline)
                        Text("Add sections for appearance, personality, motivations, skills, background or anything specific to this character.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach($draft.sections) { $section in
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("Section name", text: $section.title)
                                    .font(.headline)

                                ForEach($section.fields) { $field in
                                    VStack(alignment: .leading, spacing: 5) {
                                        TextField("Field name", text: $field.label)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.secondary)
                                        TextField("Value", text: $field.value, axis: .vertical)
                                            .lineLimit(1...6)
                                    }
                                    .padding(.vertical, 3)
                                }
                                .onDelete { section.fields.remove(atOffsets: $0) }

                                Button {
                                    section.fields.append(FieldDraft(label: "New Field", value: ""))
                                } label: {
                                    Label("Add Field", systemImage: "plus.circle")
                                }

                                Button(role: .destructive) {
                                    removeSection(id: section.id)
                                } label: {
                                    Label("Remove Section", systemImage: "trash")
                                }
                            }
                            .padding(.top, 8)
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.stack")
                                    .foregroundStyle(.tint)
                                Text(section.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Section" : section.title)
                                    .font(.headline)
                                Spacer()
                                Text("\(section.fields.count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button {
                    draft.addSection()
                } label: {
                    Label("Add Profile Section", systemImage: "plus")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } header: {
                Text("Profile Details")
            } footer: {
                Text("Sections stay collapsed until you open them, keeping long profiles manageable on iPhone. Swipe individual fields to delete them.")
            }

            if let validationMessage = draft.validationMessage {
                Section("Cannot Save") {
                    Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(character == nil ? "New Character" : "Edit Character")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveCharacter() }
                    .fontWeight(.semibold)
                    .disabled(!draft.isValid)
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

    private var portraitSection: some View {
        Section {
            HStack(spacing: 18) {
                portraitPreview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Portrait")
                        .font(.headline)
                    Text("A clear portrait makes the story and relationship screens much easier to scan.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(draft.profileImageData == nil ? "Choose Portrait" : "Change Portrait", systemImage: "photo")
                    }
                    if draft.profileImageData != nil {
                        Button("Remove Portrait", systemImage: "trash", role: .destructive) {
                            draft.profileImageData = nil
                        }
                        .font(.caption)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func removeSection(id: UUID) {
        draft.sections.removeAll { $0.id == id }
    }

    private func saveCharacter() {
        guard draft.validationMessage == nil else {
            errorMessage = draft.validationMessage
            return
        }

        _ = draft.save(to: character, project: project, in: modelContext)
        do {
            try modelContext.saveOrRollback()
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
                .frame(width: 92, height: 92)
                .clipShape(Circle())
                .overlay(Circle().stroke(.quaternary, lineWidth: 1))
                .accessibilityLabel("Current character portrait")
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .frame(width: 92, height: 92)
                .accessibilityLabel("No character portrait selected")
        }
    }
}
