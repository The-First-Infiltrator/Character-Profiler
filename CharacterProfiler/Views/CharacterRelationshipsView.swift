// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData

// MARK: - Relationship workspace

struct CharacterRelationshipsPanel: View {
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
                                let snapshot = FamilyGraphSnapshot(root: character)
                                let connected = max(0, snapshot.characters.count - 1)
                                Text("\(connected) connected family character\(connected == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if snapshot.hasGenerationConflicts {
                                    Text("Generation conflict detected")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.orange)
                                }
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
        character.markModified()
        other?.markModified()
        do {
            try modelContext.saveOrRollback()
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

        character.markModified()
        target.markModified()
        do {
            try modelContext.saveOrRollback()
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
    /// Relationship kind is stored from `source` to `target`; editing from the target perspective
    /// therefore writes the inverse directional kind back to the shared edge.
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

        // If the two people are already connected elsewhere in the family graph, a new family edge
        // must agree with the generation difference implied by that existing path.
        if kind.isFamily,
           let existingGeneration = existingRelativeGeneration(
                of: target,
                from: source,
                excluding: relationshipID
           ),
           existingGeneration != generationDelta(for: kind) {
            return "That family link conflicts with the generations already implied by the connected family tree."
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

    private static func existingRelativeGeneration(
        of target: CharacterProfile,
        from source: CharacterProfile,
        excluding relationshipID: UUID?
    ) -> Int? {
        var generationByID: [UUID: Int] = [source.id: 0]
        var queue: [CharacterProfile] = [source]
        var index = 0

        while index < queue.count {
            let current = queue[index]
            index += 1
            let currentGeneration = generationByID[current.id] ?? 0

            for relationship in current.allRelationships where relationship.id != relationshipID {
                let displayedKind = relationship.kind(from: current)
                guard displayedKind.isFamily,
                      let other = relationship.relatedCharacter(to: current) else { continue }
                let expected = currentGeneration + generationDelta(for: displayedKind)
                if generationByID[other.id] == nil {
                    generationByID[other.id] = expected
                    if other.id == target.id { return expected }
                    queue.append(other)
                }
            }
        }
        return generationByID[target.id]
    }

    static func generationDelta(for kind: RelationshipKind) -> Int {
        switch kind {
        case .parent: -1
        case .child: 1
        case .sibling, .spouse, .partner: 0
        default: 0
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
    let generationConflicts: Set<UUID>

    var hasGenerationConflicts: Bool { !generationConflicts.isEmpty }

    /// Projects the connected family component into relative generations without imposing an
    /// arbitrary character limit. Conflicting paths are reported rather than silently moving a
    /// character between rows depending on traversal order.
    init(root: CharacterProfile) {
        rootID = root.id
        var generationByID: [UUID: Int] = [root.id: 0]
        var characterByID: [UUID: CharacterProfile] = [root.id: root]
        var queue: [CharacterProfile] = [root]
        var queueIndex = 0
        var visited = Set<UUID>()
        var conflicts = Set<UUID>()

        while queueIndex < queue.count {
            let current = queue[queueIndex]
            queueIndex += 1
            guard visited.insert(current.id).inserted else { continue }
            let currentGeneration = generationByID[current.id] ?? 0

            for relationship in current.allRelationships {
                let kind = relationship.kind(from: current)
                guard kind.isFamily, let other = relationship.relatedCharacter(to: current) else { continue }
                characterByID[other.id] = other
                let expectedGeneration = currentGeneration + FamilyRelationshipRules.generationDelta(for: kind)

                if let existingGeneration = generationByID[other.id] {
                    if existingGeneration != expectedGeneration {
                        conflicts.insert(current.id)
                        conflicts.insert(other.id)
                    }
                } else {
                    generationByID[other.id] = expectedGeneration
                }

                if !visited.contains(other.id) { queue.append(other) }
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
        generationConflicts = conflicts
    }

    func generation(of character: CharacterProfile) -> Int { generations[character.id] ?? 0 }
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
                if snapshot.hasGenerationConflicts {
                    Label(
                        "Some family links imply conflicting generations. Edit the highlighted relationship structure before relying on row placement.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }

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
                    FamilyTreeNodeCard(
                        character: member,
                        isRoot: member.id == root.id,
                        hasGenerationConflict: snapshot.generationConflicts.contains(member.id)
                    )
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
    let hasGenerationConflict: Bool

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
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isRoot ? "" : "Opens this character record")
    }

    private var accessibilityLabel: String {
        var value = isRoot ? "\(character.displayName), selected family-tree character" : character.displayName
        if hasGenerationConflict { value += ", conflicting generation" }
        return value
    }

    private var card: some View {
        HStack(spacing: 8) {
            CharacterPortraitView(character: character, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(character.name).font(.subheadline.weight(.semibold)).lineLimit(2)
                if !character.storyRole.isEmpty {
                    Text(character.storyRole).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
                if hasGenerationConflict {
                    Label("Conflict", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
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
                .stroke(
                    hasGenerationConflict ? Color.orange : (isRoot ? Color.accentColor : Color.secondary.opacity(0.25)),
                    lineWidth: hasGenerationConflict || isRoot ? 3 : 1
                )
        )
        .shadow(radius: isRoot ? 4 : 1, y: 1)
    }
}
