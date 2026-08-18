#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later

from pathlib import Path

ROOT = Path(".")

def read(path):
    return (ROOT / path).read_text()

def write(path, content):
    (ROOT / path).write_text(content)

def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)

# Safer relationship endpoint semantics.
path = "CharacterProfiler/Models/CharacterProfile.swift"
s = read(path)
s = replace_once(
    s,
    '''    func kind(from character: CharacterProfile) -> RelationshipKind {
        source?.id == character.id ? kind : kind.inverse
    }
''',
    '''    /// Returns the relationship meaning from a supplied character's perspective.
    /// A non-endpoint degrades to `.other` rather than silently pretending it is the target.
    func kind(from character: CharacterProfile) -> RelationshipKind {
        if source?.id == character.id { return kind }
        if target?.id == character.id { return kind.inverse }
        return .other
    }
''',
    "CharacterRelationship.kind(from:)"
)
write(path, s)

# Archive graph validation + pre-encoded document bytes.
path = "CharacterProfiler/Support/ProjectArchive.swift"
s = read(path)
old = '''        for characterID in project.characters.map(\\.sourceID) {
            var visiting = Set<UUID>()
            if visitsAncestor(characterID, origin: characterID, visiting: &visiting) {
                throw ProjectArchiveError.invalidArchive("The archived family graph contains an ancestry cycle.")
            }
        }
    }
'''
new = '''        for characterID in project.characters.map(\\.sourceID) {
            var visiting = Set<UUID>()
            if visitsAncestor(characterID, origin: characterID, visiting: &visiting) {
                throw ProjectArchiveError.invalidArchive("The archived family graph contains an ancestry cycle.")
            }
        }

        // Every path through a family component must imply the same relative generation. Apply the
        // live-editor invariant before restore so corrupt/legacy archives cannot import a
        // contradictory graph and reveal the problem only after reconstruction.
        var familyAdjacency: [UUID: [(characterID: UUID, delta: Int)]] = [:]
        for relationship in project.relationships where relationship.kind.isFamily {
            let delta: Int
            switch relationship.kind {
            case .parent:
                delta = -1
            case .child:
                delta = 1
            case .sibling, .spouse, .partner:
                delta = 0
            default:
                continue
            }

            familyAdjacency[relationship.sourceCharacterID, default: []]
                .append((relationship.targetCharacterID, delta))
            familyAdjacency[relationship.targetCharacterID, default: []]
                .append((relationship.sourceCharacterID, -delta))
        }

        var generationByID: [UUID: Int] = [:]
        for rootID in project.characters.map(\\.sourceID) where generationByID[rootID] == nil {
            generationByID[rootID] = 0
            var queue: [UUID] = [rootID]
            var index = 0

            while index < queue.count {
                let currentID = queue[index]
                index += 1
                let currentGeneration = generationByID[currentID] ?? 0

                for edge in familyAdjacency[currentID, default: []] {
                    let expected = currentGeneration + edge.delta
                    if let existing = generationByID[edge.characterID] {
                        if existing != expected {
                            throw ProjectArchiveError.invalidArchive(
                                "The archived family graph contains conflicting generation paths."
                            )
                        }
                    } else {
                        generationByID[edge.characterID] = expected
                        queue.append(edge.characterID)
                    }
                }
            }
        }
    }
'''
s = replace_once(s, old, new, "archive family graph validation")
s = replace_once(
    s,
    '''struct ProjectArchiveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var archive: ProjectArchive

    init(archive: ProjectArchive) {
        self.archive = archive
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw ProjectArchiveError.missingFileData
        }
        archive = try ProjectArchive.decode(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try archive.encodedData())
    }
}
''',
    '''struct ProjectArchiveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    /// Pre-encoded bytes keep SwiftUI's synchronous FileDocument write callback lightweight.
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw ProjectArchiveError.missingFileData
        }
        _ = try ProjectArchive.decode(data)
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
''',
    "ProjectArchiveDocument"
)
write(path, s)

# Encode backup JSON off the interactive actor.
path = "CharacterProfiler/Views/CharacterListView.swift"
s = read(path)
s = replace_once(
    s,
    '''    @State private var exportDocument: ProjectArchiveDocument?
    @State private var exportErrorMessage: String?
''',
    '''    @State private var exportDocument: ProjectArchiveDocument?
    @State private var exportErrorMessage: String?
    @State private var isPreparingExport = false
''',
    "export state"
)
s = replace_once(
    s,
    '''                    Button { prepareExport() } label: {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                    }
''',
    '''                    Button { prepareExport() } label: {
                        if isPreparingExport {
                            Label("Preparing Backup", systemImage: "hourglass")
                        } else {
                            Label("Export Backup", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(isPreparingExport)
''',
    "export button"
)
s = replace_once(
    s,
    '''    private func prepareExport() {
        exportDocument = ProjectArchiveDocument(archive: ProjectArchive(project: project))
        showingExporter = true
    }
''',
    '''    private func prepareExport() {
        guard !isPreparingExport else { return }
        isPreparingExport = true

        // SwiftData is read on the view actor. Once projected into value types/Data, validation
        // and JSON encoding can run without blocking interactive UI work.
        let archive = ProjectArchive(project: project)
        Task {
            do {
                let data = try await Task.detached(priority: .userInitiated) {
                    try archive.encodedData()
                }.value
                exportDocument = ProjectArchiveDocument(data: data)
                showingExporter = true
            } catch {
                exportErrorMessage = error.localizedDescription
            }
            isPreparingExport = false
        }
    }
''',
    "prepareExport"
)
write(path, s)

# Make Guide ranking weights self-documenting.
path = "CharacterProfiler/Support/CharacterGuide.swift"
s = read(path)
s = replace_once(
    s,
    "enum PromptEngine {\n",
    '''enum PromptEngine {
    /// Scores are relative ranking weights, not probabilities. Catalogue prompts top out at
    /// 82 points; evidence-triggered adaptive prompts occupy the 96...112 band so concrete
    /// character evidence outranks generic development questions.
    private enum Scoring {
        static let genericCatalogueBase = 40
        static let genreCatalogueBase = 58
        static let emptyCategoryBonus = 24
        static let shallowCategoryBonus = 14
        static let mediumCategoryBonus = 6
        static let shallowDepthMaximum = 2
        static let mediumDepthMaximum = 4
    }

''',
    "Guide scoring constants"
)
s = replace_once(s, "            var score = isGenreSpecific ? 58 : 40\n", "            var score = isGenreSpecific ? Scoring.genreCatalogueBase : Scoring.genericCatalogueBase\n", "Guide base score")
s = replace_once(s, "            if depth == 0 { score += 24 }\n", "            if depth == 0 { score += Scoring.emptyCategoryBonus }\n", "Guide empty depth")
s = replace_once(s, "            else if depth <= 2 { score += 14 }\n", "            else if depth <= Scoring.shallowDepthMaximum { score += Scoring.shallowCategoryBonus }\n", "Guide shallow depth")
s = replace_once(s, "            else if depth <= 4 { score += 6 }\n", "            else if depth <= Scoring.mediumDepthMaximum { score += Scoring.mediumCategoryBonus }\n", "Guide medium depth")
s = replace_once(
    s,
    "    private static func adaptiveSuggestions(for character: CharacterProfile, in project: StoryProject) -> [GuideSuggestion] {\n",
    '''    /// Adaptive values intentionally share the documented high-priority band; the small
    /// differences only stabilize ordering between multiple evidence-triggered questions.
    private static func adaptiveSuggestions(for character: CharacterProfile, in project: StoryProject) -> [GuideSuggestion] {
''',
    "Guide adaptive score comment"
)
write(path, s)

# Regression tests for persistence failure, unrelated relationship endpoints and archive conflicts.
path = "CharacterProfilerTests/VisualStudioTests.swift"
s = read(path)
insert = '''
    private enum SyntheticPersistenceError: Error {
        case failed
    }

    @MainActor
    func testPersistenceSafetyRollsBackPendingMutationWhenCommitFails() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = StoryProject(title: "Story")
        let character = CharacterProfile(name: "Before", project: project)
        context.insert(project)
        context.insert(character)
        project.characters.append(character)
        try context.save()

        let characterID = character.id
        character.name = "After"

        XCTAssertThrowsError(
            try PersistenceSafety.commit(
                save: { throw SyntheticPersistenceError.failed },
                rollback: { context.rollback() }
            )
        )

        let fetched = try context.fetch(FetchDescriptor<CharacterProfile>())
        XCTAssertEqual(fetched.first(where: { $0.id == characterID })?.name, "Before")
    }

    @MainActor
    func testRelationshipKindDoesNotTreatUnrelatedCharacterAsEndpoint() {
        let source = CharacterProfile(name: "Source")
        let target = CharacterProfile(name: "Target")
        let unrelated = CharacterProfile(name: "Unrelated")
        let relationship = CharacterRelationship(kind: .parent, source: source, target: target)

        XCTAssertEqual(relationship.kind(from: source), .parent)
        XCTAssertEqual(relationship.kind(from: target), .child)
        XCTAssertEqual(relationship.kind(from: unrelated), .other)
    }

    @MainActor
    func testArchiveRejectsConflictingFamilyGenerationPaths() {
        let project = StoryProject(title: "Story")
        let root = CharacterProfile(name: "Root", project: project)
        let parent = CharacterProfile(name: "Parent", project: project)
        let grandparent = CharacterProfile(name: "Grandparent", project: project)
        project.characters = [root, parent, grandparent]

        let rootParent = CharacterRelationship(kind: .parent, source: root, target: parent)
        root.outgoingRelationships.append(rootParent)
        parent.incomingRelationships.append(rootParent)

        let parentGrandparent = CharacterRelationship(kind: .parent, source: parent, target: grandparent)
        parent.outgoingRelationships.append(parentGrandparent)
        grandparent.incomingRelationships.append(parentGrandparent)

        let conflict = CharacterRelationship(kind: .spouse, source: root, target: grandparent)
        root.outgoingRelationships.append(conflict)
        grandparent.incomingRelationships.append(conflict)

        XCTAssertThrowsError(try ProjectArchive(project: project).validate())
    }
'''
pos = s.rfind("\n}")
if pos == -1:
    raise RuntimeError("test insertion: class closing brace not found")
s = s[:pos] + "\n" + insert + s[pos:]
write(path, s)

print("Applied code/data audit fixes.")
