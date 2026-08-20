// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData

/// Character Guide presentation and saved-answer management.
/// Selection reasons are advisory metadata; only the author's answer is persisted as character canon.
struct CharacterGuidePanel: View {
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    let project: StoryProject
    @State private var selectedSuggestion: GuideSuggestion?
    @State private var answer = ""
    @State private var showingSavedAnswers = false
    @State private var saveErrorMessage: String?

    private var suggestions: [GuideSuggestion] {
        PromptEngine.detailedSuggestions(for: character, in: project, limit: 10)
    }

    private var savedAnswers: [PromptResponse] {
        PromptEngine.savedAnswers(for: character)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Character Guide", systemImage: "sparkles").font(.title3.bold())
                Spacer()
                if !savedAnswers.isEmpty {
                    Button("Saved Answers (\(savedAnswers.count))", systemImage: "text.book.closed") {
                        showingSavedAnswers = true
                    }
                }
            }

            Text("Questions change with the story genre and what you have already recorded. Each suggestion explains why it may be useful now. Saved answers remain editable and can be removed later.")
                .foregroundStyle(.secondary)

            if suggestions.isEmpty {
                ContentUnavailableView(
                    "No New Guide Questions",
                    systemImage: "checkmark.circle",
                    description: Text("You have answered the currently applicable suggestions. Review Saved Answers or add more profile, relationship or history detail and the Guide may discover new follow-ups.")
                )
            } else {
                ForEach(suggestions) { suggestion in
                    Button {
                        selectedSuggestion = suggestion
                        answer = ""
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            Label(suggestion.category.displayName, systemImage: suggestion.category.icon)
                                .font(.caption.weight(.semibold))
                            Text(suggestion.question)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Label(suggestion.reason, systemImage: "lightbulb")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(suggestion.reason)
                }
            }

            if !savedAnswers.isEmpty {
                Divider()
                HStack {
                    Text("Recently Answered").font(.headline)
                    Spacer()
                    Button("View All") { showingSavedAnswers = true }
                }
                ForEach(savedAnswers.prefix(3)) { response in
                    Button {
                        showingSavedAnswers = true
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(response.question).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            Text(response.answer).foregroundStyle(.secondary).lineLimit(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens all saved Guide answers for editing")
                }
            }
        }
        .sheet(item: $selectedSuggestion) { suggestion in
            let prompt = suggestion.prompt
            NavigationStack {
                Form {
                    Section { Text(prompt.question) }
                    Section("Why this question") {
                        Label(suggestion.reason, systemImage: "lightbulb")
                            .foregroundStyle(.secondary)
                    }
                    Section("Answer") {
                        TextField("Write what is true for this character", text: $answer, axis: .vertical)
                            .lineLimit(4...12)
                    }
                }
                .navigationTitle(prompt.category.displayName)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { selectedSuggestion = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveAnswer(for: prompt) }
                            .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSavedAnswers) {
            NavigationStack {
                SavedGuideAnswersView(character: character)
            }
        }
        .alert("Guide Answer Could Not Be Saved", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "Unknown save error.")
        }
    }

    private func saveAnswer(for prompt: CharacterPrompt) {
        let cleanedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedAnswer.isEmpty else { return }

        if let existing = character.response(for: prompt.id) {
            existing.answer = cleanedAnswer
            existing.question = prompt.question
            existing.category = prompt.category
            existing.updatedAt = .now
        } else {
            let response = PromptResponse(
                promptID: prompt.id,
                question: prompt.question,
                category: prompt.category,
                answer: cleanedAnswer,
                character: character
            )
            modelContext.insert(response)
            character.promptResponses.append(response)
        }
        character.markModified()
        do {
            try modelContext.saveOrRollback()
            selectedSuggestion = nil
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

private struct SavedGuideAnswersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    @State private var editingResponse: PromptResponse?
    @State private var responsePendingDeletion: PromptResponse?
    @State private var saveErrorMessage: String?

    private var answers: [PromptResponse] {
        PromptEngine.savedAnswers(for: character)
    }

    var body: some View {
        List {
            if answers.isEmpty {
                ContentUnavailableView(
                    "No Saved Guide Answers",
                    systemImage: "text.book.closed",
                    description: Text("Answers you save from Character Guide questions will appear here.")
                )
            } else {
                ForEach(answers) { response in
                    Button { editingResponse = response } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Label(response.category.displayName, systemImage: response.category.icon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(response.question).font(.headline).foregroundStyle(.primary)
                            Text(response.answer).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            responsePendingDeletion = response
                        }
                    }
                    .accessibilityHint("Opens this Guide answer for editing")
                }
            }
        }
        .navigationTitle("Saved Guide Answers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
        .sheet(item: $editingResponse) { response in
            NavigationStack {
                SavedGuideAnswerEditor(character: character, response: response)
            }
        }
        .confirmationDialog(
            "Delete Guide Answer?",
            isPresented: Binding(
                get: { responsePendingDeletion != nil },
                set: { if !$0 { responsePendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Answer", role: .destructive) { deletePendingResponse() }
            Button("Cancel", role: .cancel) { responsePendingDeletion = nil }
        } message: {
            Text("Deleting this answer removes it from the character record. The Guide question may become eligible to appear again.")
        }
        .alert("Guide Answer Could Not Be Deleted", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "Unknown save error.")
        }
    }

    private func deletePendingResponse() {
        guard let response = responsePendingDeletion else { return }
        modelContext.delete(response)
        character.markModified()
        do {
            try modelContext.saveOrRollback()
            responsePendingDeletion = nil
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

private struct SavedGuideAnswerEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    let response: PromptResponse
    @State private var answer: String
    @State private var saveErrorMessage: String?

    init(character: CharacterProfile, response: PromptResponse) {
        self.character = character
        self.response = response
        _answer = State(initialValue: response.answer)
    }

    var body: some View {
        Form {
            Section("Question") {
                Text(response.question)
                Label(response.category.displayName, systemImage: response.category.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Answer") {
                TextField("What is true for this character?", text: $answer, axis: .vertical)
                    .lineLimit(4...14)
            }
        }
        .navigationTitle("Edit Guide Answer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .alert("Guide Answer Could Not Be Saved", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "Unknown save error.")
        }
    }

    private func save() {
        let cleaned = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        response.answer = cleaned
        response.updatedAt = .now
        character.markModified()
        do {
            try modelContext.saveOrRollback()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}
