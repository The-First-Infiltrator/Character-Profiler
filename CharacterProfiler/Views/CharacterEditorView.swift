// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData
import PhotosUI

struct ProjectEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let project: StoryProject?
    private let initialDraft: ProjectDraft
    @State private var draft: ProjectDraft
    @State private var saveErrorMessage: String?
    @State private var showingDiscardConfirmation = false

    init(project: StoryProject?) {
        self.project = project
        let initial = project.map(ProjectDraft.init) ?? ProjectDraft()
        initialDraft = initial
        _draft = State(initialValue: initial)
    }

    private var hasUnsavedChanges: Bool { draft != initialDraft }

    var body: some View {
        Form {
            Section {
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
            } header: {
                CharacterProfilerSectionHeader(
                    title: "Story Details",
                    systemImage: "book.closed"
                )
            }

            Section {
                TextField(
                    "What is this story about?",
                    text: $draft.premise,
                    axis: .vertical
                )
                .lineLimit(4...10)
            } header: {
                CharacterProfilerSectionHeader(
                    title: "Premise",
                    systemImage: "text.quote",
                    accent: CharacterProfilerTheme.gold
                )
            } footer: {
                Text("The premise appears at the top of the story workspace. Genre helps Character Guide choose useful development questions and can be changed later without losing character data.")
            }
        }
        .scrollContentBackground(.hidden)
        .background { CharacterProfilerBackdrop() }
        .scrollDismissesKeyboard(.interactively)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .navigationTitle(project == nil ? "New Story" : "Edit Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { requestCancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveProject() }
                    .fontWeight(.semibold)
                    .disabled(!draft.isValid)
            }
        }
        .confirmationDialog(
            "Discard unsaved story changes?",
            isPresented: $showingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard Changes", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("Changes made in this editor have not been saved.")
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

    private func requestCancel() {
        if hasUnsavedChanges {
            showingDiscardConfirmation = true
        } else {
            dismiss()
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
    private let initialDraft: ProfileDraft
    @State private var draft: ProfileDraft
    @State private var photoItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var showingDiscardConfirmation = false

    init(project: StoryProject, character: CharacterProfile?) {
        self.project = project
        self.character = character
        let initial = character.map(ProfileDraft.init) ?? ProfileDraft()
        initialDraft = initial
        _draft = State(initialValue: initial)
    }

    private var hasUnsavedChanges: Bool { draft != initialDraft }

    var body: some View {
        Form {
            portraitSection

            Section {
                TextField("Name", text: $draft.name)
                    .textInputAutocapitalization(.words)
                TextField("Nickname", text: $draft.nickname)
                    .textInputAutocapitalization(.words)
                ViewThatFits(in: .horizontal) {
                    HStack {
                        TextField("Age", text: $draft.ageText)
                            .frame(maxWidth: .infinity)
                        Divider()
                        TextField("Pronouns", text: $draft.pronouns)
                            .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 10) {
                        TextField("Age", text: $draft.ageText)
                        TextField("Pronouns", text: $draft.pronouns)
                    }
                }
            } header: {
                CharacterProfilerSectionHeader(
                    title: "Identity",
                    systemImage: "person.text.rectangle"
                )
            }

            Section {
                TextField("Role in the story", text: $draft.storyRole)
                    .textInputAutocapitalization(.sentences)
                TextField(
                    "Short character summary",
                    text: $draft.summary,
                    axis: .vertical
                )
                .lineLimit(3...8)
            } header: {
                CharacterProfilerSectionHeader(
                    title: "Story",
                    systemImage: "book.pages",
                    accent: CharacterProfilerTheme.gold
                )
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
                                    HStack(alignment: .top, spacing: 8) {
                                        VStack(alignment: .leading, spacing: 5) {
                                            TextField("Field name", text: $field.label)
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(.secondary)
                                            TextField("Value", text: $field.value, axis: .vertical)
                                                .lineLimit(1...6)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                        Menu {
                                            Button("Delete Field", systemImage: "trash", role: .destructive) {
                                                section.fields.removeAll { $0.id == field.id }
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis.circle")
                                                .frame(minWidth: 36, minHeight: 36)
                                        }
                                        .accessibilityLabel("Actions for \(field.label.isEmpty ? "profile field" : field.label)")
                                    }
                                    .padding(.vertical, 3)
                                }

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
                CharacterProfilerSectionHeader(
                    title: "Profile Details",
                    systemImage: "rectangle.stack",
                    accent: CharacterProfilerTheme.violet
                )
            } footer: {
                Text("Sections stay collapsed until you open them, keeping long profiles manageable on iPhone. Use each field's action menu to remove it.")
            }

            if let validationMessage = draft.validationMessage {
                Section {
                    Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } header: {
                    CharacterProfilerSectionHeader(
                        title: "Cannot Save",
                        systemImage: "exclamationmark.triangle",
                        accent: .orange
                    )
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background { CharacterProfilerBackdrop() }
        .scrollDismissesKeyboard(.interactively)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .navigationTitle(character == nil ? "New Character" : "Edit Character")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { requestCancel() }
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
        .confirmationDialog(
            "Discard unsaved character changes?",
            isPresented: $showingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard Changes", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("Profile, portrait and character-detail changes made in this editor have not been saved.")
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
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    portraitPreview
                    portraitControls
                }
                VStack(alignment: .leading, spacing: 14) {
                    portraitPreview
                    portraitControls
                }
            }
            .padding(.vertical, 4)
        } header: {
            CharacterProfilerSectionHeader(
                title: "Portrait",
                systemImage: "person.crop.circle",
                accent: CharacterProfilerTheme.rose
            )
        }
    }

    private var portraitControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Visual Identity")
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func requestCancel() {
        if hasUnsavedChanges {
            showingDiscardConfirmation = true
        } else {
            dismiss()
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
                .overlay(
                    Circle().stroke(
                        LinearGradient(
                            colors: [CharacterProfilerTheme.gold, CharacterProfilerTheme.rose],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                )
                .shadow(color: CharacterProfilerTheme.rose.opacity(0.16), radius: 8, y: 4)
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
