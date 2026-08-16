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
                }.pickerStyle(.segmented)

                switch selectedSection {
                case .profile: CharacterProfilePanel(character: character)
                case .guide:
                    if let project = character.project { CharacterGuidePanel(character: character, project: project) }
                    else { Text("Assign this character to a story before using the guide.").foregroundStyle(.secondary) }
                case .people:
                    if let project = character.project { CharacterRelationshipsPanel(character: character, project: project) }
                    else { Text("Assign this character to a story before linking people.").foregroundStyle(.secondary) }
                case .history: CharacterTimelinePanel(character: character)
                case .visual:
                    if #available(iOS 18.1, *) { CharacterVisualWorkspaceView(character: character) }
                    else { VisualFeatureUnavailableView() }
                }
            }.padding()
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if character.project != nil { Button("Edit") { showingEditor = true } }
        }
        .sheet(isPresented: $showingEditor) {
            if let project = character.project { NavigationStack { CharacterEditorView(project: project, character: character) } }
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
                }.font(.caption).foregroundStyle(.secondary)
                ProgressView(value: character.completionScore)
                Text("\(Int(character.completionScore * 100))% developed").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

private struct CharacterProfilePanel: View {
    let character: CharacterProfile
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !character.summary.isEmpty { Text(character.summary).font(.body) }
            ForEach(character.sortedSections) { section in
                GroupBox(section.title) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(section.sortedFields) { field in
                            if !field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(field.label).font(.caption).foregroundStyle(.secondary)
                                    Text(field.value).frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
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

    var suggestions: [GuideSuggestion] { PromptEngine.detailedSuggestions(for: character, in: project, limit: 10) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Character Guide", systemImage: "sparkles").font(.title3.bold())
            Text("Questions change with the story genre and what you have already recorded. Each suggestion explains why it may be useful now.").foregroundStyle(.secondary)
            ForEach(suggestions) { suggestion in
                Button {
                    selectedSuggestion = suggestion
                    answer = character.response(for: suggestion.id)?.answer ?? ""
                } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        Label(suggestion.category.displayName, systemImage: suggestion.category.icon).font(.caption.weight(.semibold))
                        Text(suggestion.question).foregroundStyle(.primary).multilineTextAlignment(.leading)
                        Label(suggestion.reason, systemImage: "lightbulb")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityHint(suggestion.reason)
            }
            let answers = PromptEngine.savedAnswers(for: character)
            if !answers.isEmpty {
                Divider(); Text("Answered").font(.headline)
                ForEach(answers.prefix(6)) { response in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(response.question).font(.subheadline.weight(.semibold))
                        Text(response.answer).foregroundStyle(.secondary)
                    }
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
                    Section("Answer") { TextField("Write what is true for this character", text: $answer, axis: .vertical).lineLimit(4...12) }
                }
                .navigationTitle(prompt.category.displayName)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { selectedSuggestion = nil } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let existing = character.response(for: prompt.id) {
                                existing.answer = answer; existing.question = prompt.question; existing.updatedAt = .now
                            } else {
                                let response = PromptResponse(promptID: prompt.id, question: prompt.question, category: prompt.category, answer: answer, character: character)
                                modelContext.insert(response); character.promptResponses.append(response)
                            }
                            character.updatedAt = .now; try? modelContext.save(); selectedSuggestion = nil
                        }
                    }
                }
            }
        }
    }
}

private struct CharacterRelationshipsPanel: View {
    let character: CharacterProfile
    let project: StoryProject
    @State private var showingAdd = false

    var family: [CharacterRelationship] { character.allRelationships.filter { $0.kind(from: character).isFamily } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Label("People", systemImage: "person.2").font(.title3.bold()); Spacer(); Button("Add", systemImage: "plus") { showingAdd = true } }
            if character.allRelationships.isEmpty {
                ContentUnavailableView("No Relationships", systemImage: "person.2.slash", description: Text("Link this character to relatives, friends, rivals, partners, mentors and others."))
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
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        }
                        .padding().background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)

                    Text("Family").font(.headline)
                    ForEach(family) { RelationshipRow(character: character, relationship: $0) }
                }
                let others = character.allRelationships.filter { !$0.kind(from: character).isFamily }
                if !others.isEmpty { Text("Other Relationships").font(.headline).padding(.top, 4) }
                ForEach(others) { RelationshipRow(character: character, relationship: $0) }
            }
        }
        .sheet(isPresented: $showingAdd) { AddRelationshipView(character: character, project: project) }
    }
}

private struct RelationshipRow: View {
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    let relationship: CharacterRelationship
    var body: some View {
        if let other = relationship.relatedCharacter(to: character) {
            HStack(spacing: 10) {
                NavigationLink {
                    CharacterDetailView(character: other)
                } label: {
                    HStack(spacing: 10) {
                        CharacterPortraitView(character: other, size: 42)
                        VStack(alignment: .leading) {
                            Text(other.name).font(.headline).foregroundStyle(.primary)
                            Text(relationship.kind(from: character).displayName).font(.subheadline).foregroundStyle(.secondary)
                            if !relationship.notes.isEmpty { Text(relationship.notes).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }.buttonStyle(.plain)
                Spacer()
                Button(role: .destructive) { modelContext.delete(relationship); try? modelContext.save() } label: { Image(systemName: "trash") }
            }.padding(.vertical, 4)
        }
    }
}

private struct AddRelationshipView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    let project: StoryProject
    @State private var targetID: UUID?
    @State private var kind: RelationshipKind = .friend
    @State private var notes = ""

    var candidates: [CharacterProfile] { project.sortedCharacters.filter { $0.id != character.id } }
    private var selectedTarget: CharacterProfile? {
        guard let targetID else { return nil }
        return candidates.first { $0.id == targetID }
    }
    private var validationMessage: String? {
        guard let selectedTarget else { return nil }
        return FamilyRelationshipRules.validationMessage(source: character, target: selectedTarget, kind: kind)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Person", selection: $targetID) {
                    Text("Choose a character").tag(Optional<UUID>.none)
                    ForEach(candidates) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("Relationship", selection: $kind) { ForEach(RelationshipKind.allCases) { Text($0.displayName).tag($0) } }
                TextField("Notes", text: $notes, axis: .vertical)
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Add Relationship")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let target = selectedTarget,
                              FamilyRelationshipRules.validationMessage(source: character, target: target, kind: kind) == nil else { return }
                        let link = CharacterRelationship(kind: kind, notes: notes, source: character, target: target)
                        modelContext.insert(link); character.outgoingRelationships.append(link); target.incomingRelationships.append(link)
                        character.updatedAt = .now; target.updatedAt = .now
                        try? modelContext.save(); dismiss()
                    }.disabled(targetID == nil || validationMessage != nil)
                }
            }
        }
    }
}

enum FamilyRelationshipRules {
    static func validationMessage(source: CharacterProfile, target: CharacterProfile, kind: RelationshipKind) -> String? {
        if source.id == target.id { return "A character cannot be related to themselves." }

        let linksToTarget = source.allRelationships.filter { $0.relatedCharacter(to: source)?.id == target.id }
        if linksToTarget.contains(where: { $0.kind(from: source) == kind }) {
            return "That relationship already exists."
        }
        if kind.isFamily, let existing = linksToTarget.first(where: { $0.kind(from: source).isFamily }) {
            return "These characters are already linked as \(existing.kind(from: source).displayName.lowercased()). Remove that family link before changing it."
        }

        switch kind {
        case .parent:
            if ancestors(of: target).contains(source.id) {
                return "That would create an ancestry loop: this character is already an ancestor of the proposed parent."
            }
        case .child:
            if ancestors(of: source).contains(target.id) {
                return "That would create an ancestry loop: the proposed child is already an ancestor of this character."
            }
        case .sibling:
            if ancestors(of: source).contains(target.id) || ancestors(of: target).contains(source.id) {
                return "A direct ancestor and descendant cannot also be siblings."
            }
        default:
            break
        }
        return nil
    }

    static func ancestors(of character: CharacterProfile) -> Set<UUID> {
        var result = Set<UUID>()
        collectAncestors(of: character, into: &result, visiting: [])
        result.remove(character.id)
        return result
    }

    private static func collectAncestors(of character: CharacterProfile, into result: inout Set<UUID>, visiting: Set<UUID>) {
        guard !visiting.contains(character.id) else { return }
        var nextVisiting = visiting
        nextVisiting.insert(character.id)
        for relationship in character.allRelationships where relationship.kind(from: character) == .parent {
            guard let parent = relationship.relatedCharacter(to: character), result.insert(parent.id).inserted else { continue }
            collectAncestors(of: parent, into: &result, visiting: nextVisiting)
        }
    }
}

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
            if left == right { return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
            let members = (groups[generation] ?? []).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
                ContentUnavailableView("No Family Tree Yet", systemImage: "point.3.connected.trianglepath.dotted", description: Text("Add parent, child, sibling, spouse or partner relationships to build this character's family tree."))
            } else {
                HStack(spacing: 16) {
                    Label("Parent / child", systemImage: "arrow.up.and.down")
                    Label("Partner", systemImage: "heart")
                    Label("Sibling", systemImage: "person.2")
                    Spacer()
                    Button { baseScale = max(0.6, baseScale - 0.15) } label: { Image(systemName: "minus.magnifyingglass") }
                    Button { baseScale = 1 } label: { Image(systemName: "1.magnifyingglass") }
                    Button { baseScale = min(1.8, baseScale + 0.15) } label: { Image(systemName: "plus.magnifyingglass") }
                }
                .font(.caption).padding(.horizontal).padding(.vertical, 10)

                Divider()

                ScrollView([.horizontal, .vertical]) {
                    familyGraph(snapshot: snapshot, layout: layout)
                        .scaleEffect(scale, anchor: .topLeading)
                        .frame(width: layout.size.width * scale, height: layout.size.height * scale, alignment: .topLeading)
                }
                .gesture(
                    MagnifyGesture()
                        .updating($gestureScale) { value, state, _ in state = value.magnification }
                        .onEnded { value in baseScale = min(max(baseScale * value.magnification, 0.6), 1.8) }
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
                    guard let first = layout.positions[edge.first.id], let second = layout.positions[edge.second.id] else { continue }
                    draw(edge: edge, from: first, to: second, in: &context)
                }
            }
            .frame(width: layout.size.width, height: layout.size.height)

            ForEach(layout.generationY.keys.sorted(), id: \.self) { generation in
                if let y = layout.generationY[generation] {
                    Text(generationLabel(generation))
                        .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
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

    private func draw(edge: FamilyGraphSnapshot.Edge, from first: CGPoint, to second: CGPoint, in context: inout GraphicsContext) {
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
            context.stroke(path, with: .color(.secondary.opacity(0.62)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        case .spouse, .partner:
            path.move(to: first); path.addLine(to: second)
            context.stroke(path, with: .color(.primary.opacity(0.50)), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 5]))
        case .sibling:
            path.move(to: first); path.addLine(to: second)
            context.stroke(path, with: .color(.secondary.opacity(0.38)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 5]))
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
    }

    private var card: some View {
        HStack(spacing: 8) {
            CharacterPortraitView(character: character, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(character.name).font(.subheadline.weight(.semibold)).lineLimit(2)
                if !character.storyRole.isEmpty { Text(character.storyRole).font(.caption2).foregroundStyle(.secondary).lineLimit(2) }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(width: 156, height: 86)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isRoot ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: isRoot ? 3 : 1))
        .shadow(radius: isRoot ? 4 : 1, y: 1)
    }
}

private struct CharacterTimelinePanel: View {
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    @State private var showingAdd = false
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Label("History", systemImage: "clock.arrow.circlepath").font(.title3.bold()); Spacer(); Button("Add", systemImage: "plus") { showingAdd = true } }
            if character.lifeEvents.isEmpty {
                ContentUnavailableView("No Life Events", systemImage: "timeline.selection", description: Text("Record trauma, losses, milestones, relationships and other events that shaped the character."))
            } else {
                ForEach(character.sortedLifeEvents) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: event.kind.icon).frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title).font(.headline)
                            HStack { Text(event.kind.displayName); if !event.whenText.isEmpty { Text("• \(event.whenText)") } }.font(.caption).foregroundStyle(.secondary)
                            if !event.details.isEmpty { Text(event.details) }
                            if !event.impact.isEmpty { Text("Impact: \(event.impact)").font(.subheadline).foregroundStyle(.secondary) }
                        }
                        Spacer(); Button(role: .destructive) { modelContext.delete(event); try? modelContext.save() } label: { Image(systemName: "trash") }
                    }.padding().background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .sheet(isPresented: $showingAdd) { AddLifeEventView(character: character) }
    }
}

private struct AddLifeEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    @State private var title = ""
    @State private var kind: LifeEventKind = .milestone
    @State private var whenText = ""
    @State private var details = ""
    @State private var impact = ""
    var body: some View {
        NavigationStack {
            Form {
                TextField("Event title", text: $title)
                Picker("Type", selection: $kind) { ForEach(LifeEventKind.allCases) { Text($0.displayName).tag($0) } }
                TextField("When / age", text: $whenText)
                TextField("What happened", text: $details, axis: .vertical).lineLimit(3...8)
                TextField("How did it change them?", text: $impact, axis: .vertical).lineLimit(2...6)
            }
            .navigationTitle("Life Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let event = LifeEvent(title: title.trimmingCharacters(in: .whitespacesAndNewlines), kind: kind, whenText: whenText, details: details, impact: impact, sortOrder: character.lifeEvents.count, character: character)
                        modelContext.insert(event); character.lifeEvents.append(event); character.updatedAt = .now
                        try? modelContext.save(); dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct VisualFeatureUnavailableView: View {
    var body: some View {
        ContentUnavailableView("Visual AI Requires a Newer System", systemImage: "sparkles", description: Text("Character profiles, relationships, history and the Character Guide remain fully available. Visual AI uses Apple's Image Playground on supported devices."))
    }
}
