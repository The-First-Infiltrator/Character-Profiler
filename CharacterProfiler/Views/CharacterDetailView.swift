// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData

private enum CharacterDetailSection: String, CaseIterable, Identifiable {
    case profile, guide, people, history, visual
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct CharacterDetailView: View {
    let character: CharacterProfile
    @State private var selectedSection: CharacterDetailSection = .profile
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                CharacterHeader(character: character)
                Picker("Character section", selection: $selectedSection) {
                    ForEach(CharacterDetailSection.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Choose which part of the character record to view")

                switch selectedSection {
                case .profile:
                    CharacterProfilePanel(character: character)
                case .guide:
                    if let project = character.project {
                        CharacterGuidePanel(character: character, project: project)
                    } else {
                        ContentUnavailableView(
                            "Guide Unavailable",
                            systemImage: "books.vertical",
                            description: Text("Assign this character to a story before using the Character Guide.")
                        )
                    }
                case .people:
                    if let project = character.project {
                        CharacterRelationshipsPanel(character: character, project: project)
                    } else {
                        ContentUnavailableView(
                            "Relationships Unavailable",
                            systemImage: "person.2.slash",
                            description: Text("Assign this character to a story before linking people.")
                        )
                    }
                case .history:
                    CharacterTimelinePanel(character: character)
                case .visual:
                    if #available(iOS 18.1, *) {
                        CharacterVisualWorkspaceView(character: character)
                    } else {
                        VisualFeatureUnavailableView()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if character.project != nil {
                Button("Edit Character", systemImage: "pencil") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let project = character.project {
                NavigationStack { CharacterEditorView(project: project, character: character) }
            }
        }
    }
}

private struct CharacterHeader: View {
    let character: CharacterProfile

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            CharacterPortraitView(character: character, size: 92)
            VStack(alignment: .leading, spacing: 6) {
                Text(character.displayName).font(.title2.bold())
                if !character.storyRole.isEmpty { Text(character.storyRole).foregroundStyle(.secondary) }
                HStack(spacing: 12) {
                    if !character.ageText.isEmpty { Label(character.ageText, systemImage: "birthday.cake") }
                    if !character.pronouns.isEmpty { Text(character.pronouns) }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                ProgressView(value: character.completionScore)
                    .accessibilityLabel("Character development")
                    .accessibilityValue("\(Int(character.completionScore * 100)) percent")
                Text("\(Int(character.completionScore * 100))% developed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CharacterProfilePanel: View {
    let character: CharacterProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !character.summary.isEmpty { Text(character.summary).font(.body) }
            let populatedSections = character.sortedSections.filter { section in
                section.fields.contains { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }
            if populatedSections.isEmpty && character.summary.isEmpty {
                ContentUnavailableView(
                    "Profile Is Still Empty",
                    systemImage: "person.text.rectangle",
                    description: Text("Use Edit Character to add flexible profile sections and facts.")
                )
            } else {
                ForEach(populatedSections) { section in
                    GroupBox(section.title) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(section.sortedFields) { field in
                                if !field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(field.label).font(.caption).foregroundStyle(.secondary)
                                        Text(field.value).frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

private struct CharacterGuidePanel: View {
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    let project: StoryProject
    @State private var selectedSuggestion: GuideSuggestion?
    @State private var answer = ""
    @State private var saveErrorMessage: String?

    private var suggestions: [GuideSuggestion] {
        PromptEngine.detailedSuggestions(for: character, in: project, limit: 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Character Guide", systemImage: "sparkles").font(.title3.bold())
            Text("Questions change with the story genre and what you have already recorded. Each suggestion explains why it may be useful now.")
                .foregroundStyle(.secondary)

            if suggestions.isEmpty {
                ContentUnavailableView(
                    "No New Guide Questions",
                    systemImage: "checkmark.circle",
                    description: Text("You have answered the currently applicable suggestions. Add more profile, relationship or history detail and the Guide may discover new follow-ups.")
                )
            } else {
                ForEach(suggestions) { suggestion in
                    Button {
                        selectedSuggestion = suggestion
                        answer = character.response(for: suggestion.id)?.answer ?? ""
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

            let answers = PromptEngine.savedAnswers(for: character)
            if !answers.isEmpty {
                Divider()
                Text("Answered").font(.headline)
                ForEach(answers.prefix(6)) { response in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(response.question).font(.subheadline.weight(.semibold))
                        Text(response.answer).foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                if answers.count > 6 {
                    Text("\(answers.count - 6) more saved Guide answer\(answers.count - 6 == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    }
                }
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
        if let existing = character.response(for: prompt.id) {
            existing.answer = answer
            existing.question = prompt.question
            existing.updatedAt = .now
        } else {
            let response = PromptResponse(
                promptID: prompt.id,
                question: prompt.question,
                category: prompt.category,
                answer: answer,
                character: character
            )
            modelContext.insert(response)
            character.promptResponses.append(response)
        }
        character.updatedAt = .now
        do {
            try modelContext.save()
            selectedSuggestion = nil
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

// MARK: - Relationships

private struct CharacterRelationshipsPanel: View {
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    let project: StoryProject
    @State private var showingAdd = false
    @State private var editingRelationship: CharacterRelationship?
    @State private var relationshipPendingDeletion: CharacterRelationship?
    @State private var saveErrorMessage: String?

    private var family: [CharacterRelationship] {
        character.allRelationships.filter { $0.kind(from: character).isFamily }
    }

    private var others: [CharacterRelationship] {
        character.allRelationships.filter { !$0.kind(from: character).isFamily }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("People", systemImage: "person.2").font(.title3.bold())
                Spacer()
                Button("Add Relationship", systemImage: "plus") { showingAdd = true }
            }

            if character.allRelationships.isEmpty {
                ContentUnavailableView(
                    "No Relationships",
                    systemImage: "person.2.slash",
                    description: Text("Link this character to relatives, friends, rivals, partners, mentors and others.")
                )
            } else {
                if !family.isEmpty {
                    NavigationLink {
                        FamilyTreeView(root: character)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "point.3.connected.trianglepath.dotted").font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Open Family Tree").font(.headline)
                                let connected = max(0, FamilyGraphSnapshot(root: character).characters.count - 1)
                                Text("\(connected) connected family character\(connected == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the graphical connected family tree")

                    Text("Family").font(.headline)
                    ForEach(family) { relationship in relationshipRow(relationship) }
                }

                if !others.isEmpty {
                    Text("Other Relationships").font(.headline).padding(.top, 4)
                    ForEach(others) { relationship in relationshipRow(relationship) }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            RelationshipEditorView(character: character, project: project, relationship: nil)
        }
        .sheet(item: $editingRelationship) { relationship in
            RelationshipEditorView(character: character, project: project, relationship: relationship)
        }
        .confirmationDialog(
            "Delete Relationship?",
            isPresented: Binding(
                get: { relationshipPendingDeletion != nil },
                set: { if !$0 { relationshipPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Relationship", role: .destructive) { confirmRelationshipDeletion() }
            Button("Cancel", role: .cancel) { relationshipPendingDeletion = nil }
        } message: {
            Text(relationshipDeletionMessage)
        }
        .alert("Relationship Change Could Not Be Saved", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "Unknown save error.")
        }
    }

    @ViewBuilder
    private func relationshipRow(_ relationship: CharacterRelationship) -> some View {
        if let other = relationship.relatedCharacter(to: character) {
            HStack(spacing: 10) {
                NavigationLink {
                    CharacterDetailView(character: other)
                } label: {
                    HStack(spacing: 10) {
                        CharacterPortraitView(character: other, size: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(other.name).font(.headline).foregroundStyle(.primary)
                            Text(relationship.kind(from: character).displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if !relationship.notes.isEmpty {
                                Text(relationship.notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens \(other.name)'s character record")

                Spacer()
                Menu {
                    Button("Edit Relationship", systemImage: "pencil") {
                        editingRelationship = relationship
                    }
                    Button("Delete Relationship", systemImage: "trash", role: .destructive) {
                        relationshipPendingDeletion = relationship
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Relationship actions for \(other.name)")
            }
            .padding(.vertical, 4)
        }
    }

    private var relationshipDeletionMessage: String {
        guard let relationship = relationshipPendingDeletion,
              let other = relationship.relatedCharacter(to: character) else {
            return "This removes the selected relationship from both character records."
        }
        let kind = relationship.kind(from: character).displayName.lowercased()
        let familyNote = relationship.kind(from: character).isFamily
            ? " The family tree will update immediately because it is derived from the same relationship graph."
            : ""
        return "Remove the \(kind) relationship between \(character.name) and \(other.name)? This removes the same shared link from both character records.\(familyNote)"
    }

    private func confirmRelationshipDeletion() {
        guard let relationship = relationshipPendingDeletion else { return }
        let other = relationship.relatedCharacter(to: character)
        modelContext.delete(relationship)
        character.updatedAt = .now
        other?.updatedAt = .now
        do {
            try modelContext.save()
            relationshipPendingDeletion = nil
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

private struct RelationshipEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    let project: StoryProject
    let relationship: CharacterRelationship?

    @State private var targetID: UUID?
    @State private var kind: RelationshipKind
    @State private var notes: String
    @State private var saveErrorMessage: String?

    init(character: CharacterProfile, project: StoryProject, relationship: CharacterRelationship?) {
        self.character = character
        self.project = project
        self.relationship = relationship
        _targetID = State(initialValue: relationship?.relatedCharacter(to: character)?.id)
        _kind = State(initialValue: relationship?.kind(from: character) ?? .friend)
        _notes = State(initialValue: relationship?.notes ?? "")
    }

    private var candidates: [CharacterProfile] {
        project.sortedCharacters.filter { $0.id != character.id }
    }

    private var selectedTarget: CharacterProfile? {
        guard let targetID else { return nil }
        return candidates.first { $0.id == targetID }
    }

    private var validationMessage: String? {
        guard let selectedTarget else { return nil }
        return FamilyRelationshipRules.validationMessage(
            source: character,
            target: selectedTarget,
            kind: kind,
            excluding: relationship?.id
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Person") {
                    if let relationship, let other = relationship.relatedCharacter(to: character) {
                        LabeledContent("Character", value: other.displayName)
                        Text("The linked character stays fixed while editing. Change the relationship type or notes without deleting and rebuilding the graph edge.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        NavigationLink {
                            RelationshipCharacterPicker(selection: $targetID, characters: candidates)
                        } label: {
                            LabeledContent(
                                "Character",
                                value: selectedTarget?.displayName ?? "Choose a character"
                            )
                        }
                        if candidates.count > 20 {
                            Text("The character picker is searchable for large casts.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Relationship") {
                    Picker("Type", selection: $kind) {
                        ForEach(RelationshipKind.allCases) { relationshipKind in
                            Text(relationshipKind.displayName).tag(relationshipKind)
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...8)
                }

                if let validationMessage {
                    Section("Cannot Save") {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle(relationship == nil ? "Add Relationship" : "Edit Relationship")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRelationship() }
                        .disabled(targetID == nil || validationMessage != nil)
                }
            }
            .alert("Relationship Could Not Be Saved", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { saveErrorMessage = nil }
            } message: {
                Text(saveErrorMessage ?? "Unknown save error.")
            }
        }
    }

    private func saveRelationship() {
        guard let target = selectedTarget,
              FamilyRelationshipRules.validationMessage(
                source: character,
                target: target,
                kind: kind,
                excluding: relationship?.id
              ) == nil else { return }

        if let relationship {
            relationship.kind = RelationshipEditingRules.storedKind(
                displayedKind: kind,
                for: relationship,
                viewedFrom: character
            )
            relationship.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let link = CharacterRelationship(
                kind: kind,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                source: character,
                target: target
            )
            modelContext.insert(link)
            character.outgoingRelationships.append(link)
            target.incomingRelationships.append(link)
        }

        character.updatedAt = .now
        target.updatedAt = .now
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

private struct RelationshipCharacterPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: UUID?
    let characters: [CharacterProfile]
    @State private var searchText = ""

    private var filteredCharacters: [CharacterProfile] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return characters }
        return characters.filter { character in
            character.name.localizedCaseInsensitiveContains(term) ||
            character.nickname.localizedCaseInsensitiveContains(term) ||
            character.storyRole.localizedCaseInsensitiveContains(term) ||
            character.summary.localizedCaseInsensitiveContains(term)
        }
    }

    var body: some View {
        List {
            if filteredCharacters.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ForEach(filteredCharacters) { candidate in
                    Button {
                        selection = candidate.id
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            CharacterPortraitView(character: candidate, size: 42)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(candidate.displayName).foregroundStyle(.primary)
                                if !candidate.storyRole.isEmpty {
                                    Text(candidate.storyRole).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if selection == candidate.id {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                    }
                    .accessibilityLabel(candidate.displayName)
                    .accessibilityValue(selection == candidate.id ? "Selected" : "Not selected")
                }
            }
        }
        .navigationTitle("Choose Character")
        .searchable(text: $searchText, prompt: "Search cast")
    }
}

enum RelationshipEditingRules {
    static func storedKind(
        displayedKind: RelationshipKind,
        for relationship: CharacterRelationship,
        viewedFrom character: CharacterProfile
    ) -> RelationshipKind {
        relationship.source?.id == character.id ? displayedKind : displayedKind.inverse
    }
}

enum FamilyRelationshipRules {
    static func validationMessage(
        source: CharacterProfile,
        target: CharacterProfile,
        kind: RelationshipKind,
        excluding relationshipID: UUID? = nil
    ) -> String? {
        if source.id == target.id { return "A character cannot be related to themselves." }

        let linksToTarget = source.allRelationships.filter { relationship in
            relationship.id != relationshipID && relationship.relatedCharacter(to: source)?.id == target.id
        }
        if linksToTarget.contains(where: { $0.kind(from: source) == kind }) {
            return "That relationship already exists."
        }
        if kind.isFamily, let existing = linksToTarget.first(where: { $0.kind(from: source).isFamily }) {
            return "These characters are already linked as \(existing.kind(from: source).displayName.lowercased()). Edit or remove that family link before adding another one."
        }

        switch kind {
        case .parent:
            if ancestors(of: target, excluding: relationshipID).contains(source.id) {
                return "That would create an ancestry loop: this character is already an ancestor of the proposed parent."
            }
        case .child:
            if ancestors(of: source, excluding: relationshipID).contains(target.id) {
                return "That would create an ancestry loop: the proposed child is already an ancestor of this character."
            }
        case .sibling:
            if ancestors(of: source, excluding: relationshipID).contains(target.id) ||
                ancestors(of: target, excluding: relationshipID).contains(source.id) {
                return "A direct ancestor and descendant cannot also be siblings."
            }
        default:
            break
        }
        return nil
    }

    static func ancestors(of character: CharacterProfile, excluding relationshipID: UUID? = nil) -> Set<UUID> {
        var result = Set<UUID>()
        collectAncestors(of: character, excluding: relationshipID, into: &result, visiting: [])
        result.remove(character.id)
        return result
    }

    private static func collectAncestors(
        of character: CharacterProfile,
        excluding relationshipID: UUID?,
        into result: inout Set<UUID>,
        visiting: Set<UUID>
    ) {
        guard !visiting.contains(character.id) else { return }
        var nextVisiting = visiting
        nextVisiting.insert(character.id)
        for relationship in character.allRelationships
        where relationship.id != relationshipID && relationship.kind(from: character) == .parent {
            guard let parent = relationship.relatedCharacter(to: character),
                  result.insert(parent.id).inserted else { continue }
            collectAncestors(of: parent, excluding: relationshipID, into: &result, visiting: nextVisiting)
        }
    }
}

// MARK: - Family tree

struct FamilyGraphSnapshot {
    struct Edge: Identifiable {
        let id: UUID
        let first: CharacterProfile
        let second: CharacterProfile
        let kindFromFirst: RelationshipKind
    }

    let rootID: UUID
    let characters: [CharacterProfile]
    let generations: [UUID: Int]
    let edges: [Edge]

    init(root: CharacterProfile) {
        rootID = root.id
        var generationByID: [UUID: Int] = [root.id: 0]
        var characterByID: [UUID: CharacterProfile] = [root.id: root]
        var queue: [CharacterProfile] = [root]
        var visited = Set<UUID>()

        while !queue.isEmpty && characterByID.count < 120 {
            let current = queue.removeFirst()
            guard visited.insert(current.id).inserted else { continue }
            let currentGeneration = generationByID[current.id] ?? 0

            for relationship in current.allRelationships {
                let kind = relationship.kind(from: current)
                guard kind.isFamily, let other = relationship.relatedCharacter(to: current) else { continue }
                characterByID[other.id] = other
                if generationByID[other.id] == nil {
                    generationByID[other.id] = currentGeneration + Self.generationDelta(for: kind)
                    queue.append(other)
                } else if !visited.contains(other.id) {
                    queue.append(other)
                }
            }
        }

        var edgeIDs = Set<UUID>()
        var graphEdges: [Edge] = []
        for member in characterByID.values {
            for relationship in member.allRelationships {
                let kind = relationship.kind(from: member)
                guard kind.isFamily,
                      let other = relationship.relatedCharacter(to: member),
                      characterByID[other.id] != nil,
                      edgeIDs.insert(relationship.id).inserted else { continue }
                graphEdges.append(Edge(id: relationship.id, first: member, second: other, kindFromFirst: kind))
            }
        }

        generations = generationByID
        characters = characterByID.values.sorted {
            let left = generationByID[$0.id] ?? 0
            let right = generationByID[$1.id] ?? 0
            if left == right {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return left < right
        }
        edges = graphEdges
    }

    func generation(of character: CharacterProfile) -> Int { generations[character.id] ?? 0 }

    private static func generationDelta(for kind: RelationshipKind) -> Int {
        switch kind {
        case .parent: -1
        case .child: 1
        case .sibling, .spouse, .partner: 0
        default: 0
        }
    }
}

private struct FamilyGraphLayout {
    let size: CGSize
    let positions: [UUID: CGPoint]
    let generationY: [Int: CGFloat]

    init(snapshot: FamilyGraphSnapshot) {
        let groups = Dictionary(grouping: snapshot.characters) { snapshot.generation(of: $0) }
        let generations = groups.keys.sorted()
        let maxCount = max(1, groups.values.map(\.count).max() ?? 1)
        let horizontalSpacing: CGFloat = 190
        let verticalSpacing: CGFloat = 160
        let marginX: CGFloat = 120
        let marginY: CGFloat = 90
        let width = max(430, marginX * 2 + CGFloat(maxCount - 1) * horizontalSpacing)
        let height = max(260, marginY * 2 + CGFloat(max(0, generations.count - 1)) * verticalSpacing)

        var result: [UUID: CGPoint] = [:]
        var rowY: [Int: CGFloat] = [:]
        for (rowIndex, generation) in generations.enumerated() {
            let members = (groups[generation] ?? []).sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            let y = marginY + CGFloat(rowIndex) * verticalSpacing
            rowY[generation] = y
            let rowWidth = CGFloat(max(0, members.count - 1)) * horizontalSpacing
            let startX = width / 2 - rowWidth / 2
            for (index, member) in members.enumerated() {
                result[member.id] = CGPoint(x: startX + CGFloat(index) * horizontalSpacing, y: y)
            }
        }
        size = CGSize(width: width, height: height)
        positions = result
        generationY = rowY
    }
}

struct FamilyTreeView: View {
    let root: CharacterProfile
    @State private var baseScale: CGFloat = 1
    @GestureState private var gestureScale: CGFloat = 1

    private var snapshot: FamilyGraphSnapshot { FamilyGraphSnapshot(root: root) }
    private var scale: CGFloat { min(max(baseScale * gestureScale, 0.6), 1.8) }

    var body: some View {
        let snapshot = snapshot
        let layout = FamilyGraphLayout(snapshot: snapshot)
        VStack(spacing: 0) {
            if snapshot.characters.count <= 1 {
                ContentUnavailableView(
                    "No Family Tree Yet",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    description: Text("Add parent, child, sibling, spouse or partner relationships to build this character's family tree.")
                )
            } else {
                HStack(spacing: 16) {
                    Label("Parent / child", systemImage: "arrow.up.and.down")
                    Label("Partner", systemImage: "heart")
                    Label("Sibling", systemImage: "person.2")
                    Spacer()
                    Button { baseScale = max(0.6, baseScale - 0.15) } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .accessibilityLabel("Zoom out")
                    Button { baseScale = 1 } label: { Image(systemName: "1.magnifyingglass") }
                        .accessibilityLabel("Reset zoom")
                    Button { baseScale = min(1.8, baseScale + 0.15) } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .accessibilityLabel("Zoom in")
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, 10)

                Divider()

                ScrollView([.horizontal, .vertical]) {
                    familyGraph(snapshot: snapshot, layout: layout)
                        .scaleEffect(scale, anchor: .topLeading)
                        .frame(
                            width: layout.size.width * scale,
                            height: layout.size.height * scale,
                            alignment: .topLeading
                        )
                }
                .gesture(
                    MagnifyGesture()
                        .updating($gestureScale) { value, state, _ in state = value.magnification }
                        .onEnded { value in
                            baseScale = min(max(baseScale * value.magnification, 0.6), 1.8)
                        }
                )
            }
        }
        .navigationTitle("\(root.name) — Family")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func familyGraph(snapshot: FamilyGraphSnapshot, layout: FamilyGraphLayout) -> some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                for edge in snapshot.edges {
                    guard let first = layout.positions[edge.first.id],
                          let second = layout.positions[edge.second.id] else { continue }
                    draw(edge: edge, from: first, to: second, in: &context)
                }
            }
            .frame(width: layout.size.width, height: layout.size.height)
            .accessibilityHidden(true)

            ForEach(layout.generationY.keys.sorted(), id: \.self) { generation in
                if let y = layout.generationY[generation] {
                    Text(generationLabel(generation))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .position(x: 54, y: y)
                }
            }

            ForEach(snapshot.characters) { member in
                if let point = layout.positions[member.id] {
                    FamilyTreeNodeCard(character: member, isRoot: member.id == root.id)
                        .position(point)
                }
            }
        }
        .frame(width: layout.size.width, height: layout.size.height)
    }

    private func draw(
        edge: FamilyGraphSnapshot.Edge,
        from first: CGPoint,
        to second: CGPoint,
        in context: inout GraphicsContext
    ) {
        var path = Path()
        switch edge.kindFromFirst {
        case .parent, .child:
            let upper = first.y <= second.y ? first : second
            let lower = first.y <= second.y ? second : first
            let midY = (upper.y + lower.y) / 2
            path.move(to: CGPoint(x: upper.x, y: upper.y + 48))
            path.addLine(to: CGPoint(x: upper.x, y: midY))
            path.addLine(to: CGPoint(x: lower.x, y: midY))
            path.addLine(to: CGPoint(x: lower.x, y: lower.y - 48))
            context.stroke(
                path,
                with: .color(.secondary.opacity(0.62)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        case .spouse, .partner:
            path.move(to: first)
            path.addLine(to: second)
            context.stroke(
                path,
                with: .color(.primary.opacity(0.50)),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 5])
            )
        case .sibling:
            path.move(to: first)
            path.addLine(to: second)
            context.stroke(
                path,
                with: .color(.secondary.opacity(0.38)),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 5])
            )
        default:
            break
        }
    }

    private func generationLabel(_ generation: Int) -> String {
        switch generation {
        case -2: "Grandparents"
        case -1: "Parents"
        case 0: "Generation"
        case 1: "Children"
        case 2: "Grandchildren"
        default:
            generation < 0 ? "\(-generation) generations earlier" : "\(generation) generations later"
        }
    }
}

private struct FamilyTreeNodeCard: View {
    let character: CharacterProfile
    let isRoot: Bool

    var body: some View {
        Group {
            if isRoot {
                card
            } else {
                NavigationLink { CharacterDetailView(character: character) } label: { card }
                    .buttonStyle(.plain)
            }
        }
        .frame(width: 156, height: 96)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isRoot ? "\(character.displayName), selected family-tree character" : character.displayName)
        .accessibilityHint(isRoot ? "" : "Opens this character record")
    }

    private var card: some View {
        HStack(spacing: 8) {
            CharacterPortraitView(character: character, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(character.name).font(.subheadline.weight(.semibold)).lineLimit(2)
                if !character.storyRole.isEmpty {
                    Text(character.storyRole).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(width: 156, height: 86)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isRoot ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: isRoot ? 3 : 1)
        )
        .shadow(radius: isRoot ? 4 : 1, y: 1)
    }
}

// MARK: - History

enum LifeEventOrdering {
    static func reorderedIDs(_ ids: [UUID], moving id: UUID, by offset: Int) -> [UUID] {
        guard let source = ids.firstIndex(of: id) else { return ids }
        let destination = min(max(source + offset, 0), max(ids.count - 1, 0))
        guard destination != source else { return ids }
        var result = ids
        let value = result.remove(at: source)
        result.insert(value, at: destination)
        return result
    }

    @MainActor
    static func move(_ event: LifeEvent, by offset: Int, in character: CharacterProfile) {
        let current = character.sortedLifeEvents
        let orderedIDs = reorderedIDs(current.map(\.id), moving: event.id, by: offset)
        let orderByID = Dictionary(uniqueKeysWithValues: orderedIDs.enumerated().map { ($0.element, $0.offset) })
        for item in character.lifeEvents {
            if let order = orderByID[item.id] { item.sortOrder = order }
        }
    }

    @MainActor
    static func normalize(in character: CharacterProfile) {
        for (index, event) in character.sortedLifeEvents.enumerated() {
            event.sortOrder = index
        }
    }
}

private struct CharacterTimelinePanel: View {
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    @State private var showingAdd = false
    @State private var editingEvent: LifeEvent?
    @State private var eventPendingDeletion: LifeEvent?
    @State private var saveErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("History", systemImage: "clock.arrow.circlepath").font(.title3.bold())
                Spacer()
                Button("Add Life Event", systemImage: "plus") { showingAdd = true }
            }

            if character.lifeEvents.isEmpty {
                ContentUnavailableView(
                    "No Life Events",
                    systemImage: "timeline.selection",
                    description: Text("Record trauma, losses, milestones, relationships and other events that shaped the character.")
                )
            } else {
                Text("Events are shown in author-controlled chronological order. Use the event menu to move an entry earlier or later when the free-text age/date cannot be sorted automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let events = character.sortedLifeEvents
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    historyRow(event, index: index, total: events.count)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            LifeEventEditorView(character: character, event: nil)
        }
        .sheet(item: $editingEvent) { event in
            LifeEventEditorView(character: character, event: event)
        }
        .confirmationDialog(
            "Delete Life Event?",
            isPresented: Binding(
                get: { eventPendingDeletion != nil },
                set: { if !$0 { eventPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Life Event", role: .destructive) { confirmEventDeletion() }
            Button("Cancel", role: .cancel) { eventPendingDeletion = nil }
        } message: {
            Text(eventDeletionMessage)
        }
        .alert("History Change Could Not Be Saved", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "Unknown save error.")
        }
    }

    private func historyRow(_ event: LifeEvent, index: Int, total: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 5) {
                ZStack {
                    Circle().fill(.thinMaterial).frame(width: 34, height: 34)
                    Image(systemName: event.kind.icon).font(.caption.weight(.semibold))
                }
                if index < total - 1 {
                    Rectangle().fill(.quaternary).frame(width: 2, height: 52)
                }
            }
            .accessibilityHidden(true)

            Button { editingEvent = event } label: {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(event.title).font(.headline).foregroundStyle(.primary)
                        Spacer()
                        Text("#\(index + 1)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 5) {
                        Text(event.kind.displayName)
                        if !event.whenText.isEmpty { Text("• \(event.whenText)") }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    if !event.details.isEmpty {
                        Text(event.details).foregroundStyle(.primary).multilineTextAlignment(.leading)
                    }
                    if !event.impact.isEmpty {
                        Label(event.impact, systemImage: "arrow.triangle.branch")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(eventAccessibilityLabel(event, position: index + 1))
            .accessibilityHint("Opens this life event for editing")

            Menu {
                Button("Edit", systemImage: "pencil") { editingEvent = event }
                Button("Move Earlier", systemImage: "arrow.up") { move(event, by: -1) }
                    .disabled(index == 0)
                Button("Move Later", systemImage: "arrow.down") { move(event, by: 1) }
                    .disabled(index == total - 1)
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) { eventPendingDeletion = event }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Actions for \(event.title)")
        }
    }

    private func eventAccessibilityLabel(_ event: LifeEvent, position: Int) -> String {
        var parts = ["History item \(position)", event.title, event.kind.displayName]
        if !event.whenText.isEmpty { parts.append(event.whenText) }
        if !event.details.isEmpty { parts.append(event.details) }
        if !event.impact.isEmpty { parts.append("Impact: \(event.impact)") }
        return parts.joined(separator: ", ")
    }

    private func move(_ event: LifeEvent, by offset: Int) {
        LifeEventOrdering.move(event, by: offset, in: character)
        character.updatedAt = .now
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private var eventDeletionMessage: String {
        guard let event = eventPendingDeletion else {
            return "This permanently removes the selected history entry."
        }
        return "Delete “\(event.title)” from \(character.name)'s history? This removes the event and its recorded details/impact. It can also change which adaptive Guide questions are suggested."
    }

    private func confirmEventDeletion() {
        guard let event = eventPendingDeletion else { return }
        modelContext.delete(event)
        character.updatedAt = .now
        LifeEventOrdering.normalize(in: character)
        do {
            try modelContext.save()
            eventPendingDeletion = nil
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

private struct LifeEventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    let event: LifeEvent?

    @State private var title: String
    @State private var kind: LifeEventKind
    @State private var whenText: String
    @State private var details: String
    @State private var impact: String
    @State private var saveErrorMessage: String?

    init(character: CharacterProfile, event: LifeEvent?) {
        self.character = character
        self.event = event
        _title = State(initialValue: event?.title ?? "")
        _kind = State(initialValue: event?.kind ?? .milestone)
        _whenText = State(initialValue: event?.whenText ?? "")
        _details = State(initialValue: event?.details ?? "")
        _impact = State(initialValue: event?.impact ?? "")
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Event title", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(LifeEventKind.allCases) { eventKind in
                            Text(eventKind.displayName).tag(eventKind)
                        }
                    }
                    TextField("When / age", text: $whenText)
                }
                Section("What Happened") {
                    TextField("Describe the event", text: $details, axis: .vertical).lineLimit(3...10)
                }
                Section("Lasting Impact") {
                    TextField("How did it change them?", text: $impact, axis: .vertical).lineLimit(2...8)
                    Text("Impact can influence adaptive Character Guide questions later.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(event == nil ? "Add Life Event" : "Edit Life Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEvent() }.disabled(trimmedTitle.isEmpty)
                }
            }
            .alert("Life Event Could Not Be Saved", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { saveErrorMessage = nil }
            } message: {
                Text(saveErrorMessage ?? "Unknown save error.")
            }
        }
    }

    private func saveEvent() {
        let cleanedWhen = whenText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedImpact = impact.trimmingCharacters(in: .whitespacesAndNewlines)

        if let event {
            event.title = trimmedTitle
            event.kind = kind
            event.whenText = cleanedWhen
            event.details = cleanedDetails
            event.impact = cleanedImpact
        } else {
            let newEvent = LifeEvent(
                title: trimmedTitle,
                kind: kind,
                whenText: cleanedWhen,
                details: cleanedDetails,
                impact: cleanedImpact,
                sortOrder: character.lifeEvents.count,
                character: character
            )
            modelContext.insert(newEvent)
            character.lifeEvents.append(newEvent)
        }

        LifeEventOrdering.normalize(in: character)
        character.updatedAt = .now
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
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
