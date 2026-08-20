// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData
import PhotosUI
import UIKit
#if canImport(ImagePlayground)
import ImagePlayground
#endif

struct VisualWorkspaceSnapshot: Equatable {
    let hasCanonicalVisual: Bool
    let referenceCount: Int
    let availableAngles: [VisualAngle]
    let duplicateAngles: [VisualAngle]

    init(character: CharacterProfile) {
        hasCanonicalVisual = character.generatedVisualData != nil
        referenceCount = character.referenceImages.count

        let grouped = Dictionary(grouping: character.visualFrames, by: \CharacterVisualFrame.angle)
        availableAngles = VisualAngle.allCases.filter { grouped[$0]?.isEmpty == false }
        duplicateAngles = VisualAngle.allCases.filter { (grouped[$0]?.count ?? 0) > 1 }
    }

    var missingAngles: [VisualAngle] {
        VisualAngle.allCases.filter { !availableAngles.contains($0) }
    }

    var completedAngleCount: Int { availableAngles.count }
    var isTurnaroundComplete: Bool { missingAngles.isEmpty }
    var turnaroundProgress: Double { Double(completedAngleCount) / Double(VisualAngle.allCases.count) }
}

extension VisualAngle {
    func advanced(by offset: Int) -> VisualAngle {
        let angles = Self.allCases
        guard let index = angles.firstIndex(of: self), !angles.isEmpty else { return self }
        let count = angles.count
        let wrapped = ((index + offset) % count + count) % count
        return angles[wrapped]
    }
}

enum VisualReferenceOrdering {
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
    static func move(_ reference: CharacterReferenceImage, by offset: Int, in character: CharacterProfile) {
        let current = character.sortedReferenceImages
        let orderedIDs = reorderedIDs(current.map(\.id), moving: reference.id, by: offset)
        let orderByID = Dictionary(uniqueKeysWithValues: orderedIDs.enumerated().map { ($0.element, $0.offset) })
        for item in character.referenceImages {
            if let order = orderByID[item.id] { item.sortOrder = order }
        }
    }

    @MainActor
    static func normalize(in character: CharacterProfile) {
        for (index, item) in character.sortedReferenceImages.enumerated() {
            item.sortOrder = index
        }
    }
}

#if canImport(ImagePlayground)
@available(iOS 18.1, *)
struct CharacterVisualWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground
    @Environment(\.reportPersistenceFailure) private var reportPersistenceFailure

    let character: CharacterProfile

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingGenerator = false
    @State private var generationAngle: VisualAngle?
    @State private var viewerAngle: VisualAngle = .front
    @State private var editingReference: CharacterReferenceImage?
    @State private var showingCanonicalReplacementOptions = false
    @State private var resetTurnaroundAfterCanonicalSuccess = false
    @State private var showingClearVisualSet = false
    @State private var showingResetTurnaround = false
    @State private var errorMessage: String?
    @State private var appearanceNotesDraft: String
    @State private var appearanceSaveTask: Task<Void, Never>?
    @State private var isDisappearing = false

    init(character: CharacterProfile) {
        self.character = character
        _appearanceNotesDraft = State(initialValue: character.visualDescription)
    }

    private var snapshot: VisualWorkspaceSnapshot { VisualWorkspaceSnapshot(character: character) }

    private var sourceImage: Image? {
        if generationAngle != nil {
            guard let data = character.generatedVisualData, let image = UIImage(data: data) else { return nil }
            return Image(uiImage: image)
        }
        if let board = referenceBoardImage() { return Image(uiImage: board) }
        return nil
    }

    private var concept: String {
        if let angle = generationAngle {
            return baseDescription
                + " Use the supplied canonical character image as the identity source. Do not redesign the person, clothing, equipment, proportions or colour scheme. "
                + angle.generationInstruction
        }
        return baseDescription
            + " Create one canonical, consistent, single-character full-body reference on a plain unobtrusive background. Preserve the supplied references faithfully. Do not create a story scene."
    }

    private var baseDescription: String {
        var parts = ["Character named \(character.name)."]
        if let project = character.project { parts.append("Genre: \(project.genreDisplayName).") }
        if !character.storyRole.isEmpty { parts.append("Story role: \(character.storyRole).") }
        if !character.summary.isEmpty { parts.append(character.summary) }
        if !appearanceNotesDraft.isEmpty { parts.append("Appearance instructions: \(appearanceNotesDraft)") }
        let fields = character.sections.flatMap { section in
            section.fields.compactMap { field in
                let value = field.value.trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : "\(field.label): \(value)"
            }
        }
        if !fields.isEmpty { parts.append("Known appearance/profile facts: " + fields.joined(separator: "; ")) }
        return parts.joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Character Visual Studio", systemImage: "person.crop.rectangle.stack")
                .font(.title3.bold())
                .foregroundStyle(CharacterProfilerTheme.violet)
            Text("Establish one canonical look from the character record and references, then build an eight-view turnaround from that canonical image.")
                .foregroundStyle(.secondary)

            if !supportsImagePlayground {
                Label {
                    Text("Image generation is unavailable on this device or in its current system environment. Existing references, canonical images and turnaround frames remain viewable and editable.")
                } icon: {
                    Image(systemName: "sparkles.slash")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background { CharacterProfilerCardSurface(accent: CharacterProfilerTheme.violet) }
            }

            referencePicturesSection
            appearanceNotesSection
            canonicalCharacterSection
            turnaroundSection
        }
        .onChange(of: selectedPhotos) { _, items in importReferences(items) }
        .onChange(of: appearanceNotesDraft) { _, _ in scheduleAppearanceNotesSave() }
        .onAppear { isDisappearing = false }
        .onDisappear {
            isDisappearing = true
            flushAppearanceNotes()
        }
        .sheet(item: $editingReference) { reference in
            VisualReferenceEditor(reference: reference, character: character)
        }
        .confirmationDialog(
            "Replace the canonical visual?",
            isPresented: $showingCanonicalReplacementOptions,
            titleVisibility: .visible
        ) {
            Button("Regenerate and reset turnaround", role: .destructive) {
                beginCanonicalGeneration(resetTurnaroundOnSuccess: true)
            }
            Button("Regenerate but keep existing views") {
                beginCanonicalGeneration(resetTurnaroundOnSuccess: false)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Existing angle views were created from the current canonical image. Resetting them after a successful replacement is the safest way to avoid a mixed visual identity.")
        }
        .confirmationDialog(
            "Clear the visual set?",
            isPresented: $showingClearVisualSet,
            titleVisibility: .visible
        ) {
            Button("Clear canonical image and turnaround", role: .destructive) { clearVisualSet() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Reference pictures and appearance notes are kept. A profile portrait already copied from the canonical image is also kept.")
        }
        .confirmationDialog(
            "Reset all turnaround views?",
            isPresented: $showingResetTurnaround,
            titleVisibility: .visible
        ) {
            Button("Delete all angle views", role: .destructive) { clearTurnaround() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The canonical image, reference pictures and appearance notes are kept.")
        }
        .alert("Visual Studio", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .imagePlaygroundSheet(
            isPresented: $showingGenerator,
            concept: concept,
            sourceImage: sourceImage,
            onCompletion: acceptGeneratedImage,
            onCancellation: cancelGeneration
        )
    }

    private var referencePicturesSection: some View {
        GroupBox("Reference Pictures") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(character.referenceImages.count) of 6 references")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if character.referenceImages.count < 6 {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 6 - character.referenceImages.count,
                            matching: .images
                        ) {
                            Label("Add", systemImage: "photo.on.rectangle.angled")
                        }
                    }
                }

                if character.referenceImages.isEmpty {
                    Text("Add face, full-body, clothing, hair or other visual references. Tap a reference later to rename or reorder it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(character.sortedReferenceImages) { reference in
                                Button { editingReference = reference } label: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        if let image = UIImage(data: reference.imageData) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 105, height: 130)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        Text(reference.label.isEmpty ? "Reference" : reference.label)
                                            .font(.caption2)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                            .frame(width: 105, alignment: .leading)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Edit \(reference.label.isEmpty ? "reference image" : reference.label)")
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var appearanceNotesSection: some View {
        GroupBox("Appearance Notes") {
            TextField(
                "Details the pictures do not show—height, build, scars, clothing, equipment, colours…",
                text: $appearanceNotesDraft,
                axis: .vertical
            )
            .lineLimit(4...10)
        }
    }

    private var canonicalCharacterSection: some View {
        GroupBox("Canonical Character") {
            VStack(alignment: .leading, spacing: 12) {
                if let data = character.generatedVisualData, let image = UIImage(data: data) {
                    Label("Canonical visual established", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 420)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    HStack {
                        Button("Use as Portrait", systemImage: "person.crop.circle") {
                            character.profileImageData = data
                            character.markModified()
                            saveContext()
                        }
                        Button("Replace", systemImage: "sparkles") {
                            if character.visualFrames.isEmpty {
                                beginCanonicalGeneration(resetTurnaroundOnSuccess: false)
                            } else {
                                showingCanonicalReplacementOptions = true
                            }
                        }
                        .disabled(!supportsImagePlayground)
                    }

                    Button("Clear Visual Set", systemImage: "trash", role: .destructive) {
                        showingClearVisualSet = true
                    }
                    .font(.caption)
                } else {
                    ContentUnavailableView(
                        "No Canonical Visual Yet",
                        systemImage: "person.crop.rectangle.badge.plus",
                        description: Text("Create one from the character record, profile portrait and reference pictures before generating turnaround angles.")
                    )
                    Button("Create Canonical Visual", systemImage: "sparkles") {
                        flushAppearanceNotes()
                        beginCanonicalGeneration(resetTurnaroundOnSuccess: false)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!supportsImagePlayground)

                    if !character.visualFrames.isEmpty {
                        Label("This character has turnaround frames but no canonical image. Create a canonical visual before replacing or filling missing angles.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var turnaroundSection: some View {
        let state = snapshot
        return GroupBox("360° Turnaround") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("\(state.completedAngleCount) of 8 views", systemImage: state.isTurnaroundComplete ? "checkmark.circle.fill" : "circle.dotted")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int(state.turnaroundProgress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: state.turnaroundProgress)
                    .tint(CharacterProfilerTheme.violet)

                if !state.duplicateAngles.isEmpty {
                    Label("Duplicate stored frames detected for: \(state.duplicateAngles.map(\.displayName).joined(separator: ", ")). Delete or regenerate the duplicate views before relying on the turnaround.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if let frame = frame(for: viewerAngle), let image = UIImage(data: frame.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 420)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 12).onEnded { value in
                            rotate(by: value.translation.width)
                        })
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "square.dashed")
                            .font(.system(size: 42))
                            .foregroundStyle(.secondary)
                        Text("\(viewerAngle.displayName) view is missing")
                            .font(.headline)
                        if character.generatedVisualData == nil {
                            Text("Create the canonical visual first.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if supportsImagePlayground {
                            Button("Generate This View", systemImage: "sparkles") {
                                beginAngleGeneration(viewerAngle)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Text("Image generation is unavailable on this device.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .background(.quaternary.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 12).onEnded { value in
                        rotate(by: value.translation.width)
                    })
                }

                HStack {
                    Button { viewerAngle = viewerAngle.advanced(by: -1) } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text("\(viewerAngle.displayName) • \(viewerAngle.degrees)° — drag or use arrows")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Button { viewerAngle = viewerAngle.advanced(by: 1) } label: {
                        Image(systemName: "chevron.right")
                    }
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(VisualAngle.allCases) { angle in
                            turnaroundTile(angle)
                        }
                    }
                }

                if !state.missingAngles.isEmpty {
                    Text("Missing: " + state.missingAngles.map { "\($0.displayName) (\($0.degrees)°)" }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Generate Next Missing View", systemImage: "sparkles") {
                        if let next = state.missingAngles.first { beginAngleGeneration(next) }
                    }
                    .disabled(character.generatedVisualData == nil || !supportsImagePlayground)
                } else {
                    Label("Complete eight-view turnaround", systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                }

                if !character.visualFrames.isEmpty {
                    Button("Reset Turnaround", systemImage: "arrow.counterclockwise", role: .destructive) {
                        showingResetTurnaround = true
                    }
                    .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func turnaroundTile(_ angle: VisualAngle) -> some View {
        let existing = frame(for: angle)
        Button { viewerAngle = angle } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    if let existing, let image = UIImage(data: existing.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .green)
                            .padding(4)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                            .frame(width: 72, height: 88)
                            .overlay(Image(systemName: "plus"))
                    }
                }
                Text(angle.displayName).font(.caption2).lineLimit(1)
                Text("\(angle.degrees)°").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
            }
            .padding(4)
            .background(viewerAngle == angle ? Color.accentColor.opacity(0.14) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if existing != nil, character.generatedVisualData != nil, supportsImagePlayground {
                Button("Regenerate View", systemImage: "sparkles") { beginAngleGeneration(angle) }
            }
            if existing != nil {
                Button("Delete View", systemImage: "trash", role: .destructive) { deleteFrame(angle) }
            }
        }
        .accessibilityLabel("\(angle.displayName), \(angle.degrees) degrees, \(existing == nil ? "missing" : "complete")")
    }

    private func frame(for angle: VisualAngle) -> CharacterVisualFrame? {
        character.visualFrames.first { $0.angle == angle }
    }

    private func rotate(by translation: CGFloat) {
        viewerAngle = viewerAngle.advanced(by: translation < 0 ? 1 : -1)
    }

    private func beginCanonicalGeneration(resetTurnaroundOnSuccess: Bool) {
        guard supportsImagePlayground else {
            errorMessage = "Image Playground is not available on this device or in its current system environment."
            return
        }
        flushAppearanceNotes()
        generationAngle = nil
        resetTurnaroundAfterCanonicalSuccess = resetTurnaroundOnSuccess
        showingGenerator = true
    }

    private func beginAngleGeneration(_ angle: VisualAngle) {
        guard supportsImagePlayground else {
            errorMessage = "Image Playground is not available on this device or in its current system environment."
            return
        }
        guard character.generatedVisualData != nil else {
            errorMessage = "Create a canonical character visual before generating turnaround angles."
            return
        }
        generationAngle = angle
        resetTurnaroundAfterCanonicalSuccess = false
        viewerAngle = angle
        showingGenerator = true
    }

    private func acceptGeneratedImage(_ url: URL) {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            errorMessage = "The generated image could not be read. \(error.localizedDescription)"
            generationAngle = nil
            resetTurnaroundAfterCanonicalSuccess = false
            return
        }

        guard let normalised = CharacterImageProcessor.normalisedJPEGData(from: data, maxDimension: 1600) else {
            errorMessage = "The generated image could not be imported into Character Profiler."
            generationAngle = nil
            resetTurnaroundAfterCanonicalSuccess = false
            return
        }

        if let angle = generationAngle {
            if let existing = frame(for: angle) {
                existing.imageData = normalised
                existing.generatedAt = .now
            } else {
                let frame = CharacterVisualFrame(angle: angle, imageData: normalised, character: character)
                modelContext.insert(frame)
                character.visualFrames.append(frame)
            }
            viewerAngle = angle
        } else {
            if resetTurnaroundAfterCanonicalSuccess { clearTurnaround(save: false) }
            character.generatedVisualData = normalised
        }

        character.markModified()
        saveContext()
        generationAngle = nil
        resetTurnaroundAfterCanonicalSuccess = false
    }

    private func cancelGeneration() {
        generationAngle = nil
        resetTurnaroundAfterCanonicalSuccess = false
    }

    private func clearTurnaround(save: Bool = true) {
        let frames = character.visualFrames
        character.visualFrames.removeAll()
        for frame in frames { modelContext.delete(frame) }
        viewerAngle = .front
        character.markModified()
        if save { saveContext() }
    }

    private func clearVisualSet() {
        clearTurnaround(save: false)
        character.generatedVisualData = nil
        character.markModified()
        saveContext()
    }

    private func deleteFrame(_ angle: VisualAngle) {
        let matches = character.visualFrames.filter { $0.angle == angle }
        character.visualFrames.removeAll { $0.angle == angle }
        for frame in matches { modelContext.delete(frame) }
        character.markModified()
        saveContext()
    }

    private func importReferences(_ items: [PhotosPickerItem]) {
        Task {
            let capacity = max(0, 6 - character.referenceImages.count)
            var importedData: [Data] = []
            var failures = 0

            for item in items.prefix(capacity) {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let normalised = CharacterImageProcessor.normalisedJPEGData(from: data) else {
                        failures += 1
                        continue
                    }
                    importedData.append(normalised)
                } catch {
                    failures += 1
                }
            }

            await MainActor.run {
                for normalised in importedData {
                    let nextNumber = character.referenceImages.count + 1
                    let reference = CharacterReferenceImage(
                        label: "Reference \(nextNumber)",
                        sortOrder: character.referenceImages.count,
                        imageData: normalised,
                        character: character
                    )
                    modelContext.insert(reference)
                    character.referenceImages.append(reference)
                }

                VisualReferenceOrdering.normalize(in: character)
                selectedPhotos = []
                if !importedData.isEmpty {
                    character.markModified()
                    saveContext()
                }
                if failures > 0 {
                    errorMessage = "\(failures) selected image\(failures == 1 ? "" : "s") could not be imported."
                }
            }
        }
    }

    /// Builds one source board from the profile portrait plus author references. The portrait is
    /// intentionally not discarded when reference images exist because it may be the strongest face/identity cue.
    private func referenceBoardImage() -> UIImage? {
        var images: [UIImage] = []
        if let data = character.profileImageData, let portrait = UIImage(data: data) {
            images.append(portrait)
        }
        images.append(contentsOf: character.sortedReferenceImages.compactMap { UIImage(data: $0.imageData) })
        guard !images.isEmpty else { return nil }

        let canvas = CGSize(width: 1200, height: 1200)
        let columns = images.count == 1 ? 1 : 2
        let rows = Int(ceil(Double(images.count) / Double(columns)))
        let cell = CGSize(width: canvas.width / CGFloat(columns), height: canvas.height / CGFloat(rows))

        return UIGraphicsImageRenderer(size: canvas).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: canvas))
            for (index, image) in images.enumerated() {
                let column = index % columns
                let row = index / columns
                let rect = CGRect(
                    x: CGFloat(column) * cell.width,
                    y: CGFloat(row) * cell.height,
                    width: cell.width,
                    height: cell.height
                )
                let scale = min(rect.width / image.size.width, rect.height / image.size.height)
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                image.draw(in: CGRect(
                    x: rect.midX - size.width / 2,
                    y: rect.midY - size.height / 2,
                    width: size.width,
                    height: size.height
                ))
            }
        }
    }

    private func scheduleAppearanceNotesSave() {
        appearanceSaveTask?.cancel()
        appearanceSaveTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 550_000_000)
            } catch {
                return
            }
            saveAppearanceNotesIfNeeded()
        }
    }

    private func flushAppearanceNotes() {
        appearanceSaveTask?.cancel()
        appearanceSaveTask = nil
        saveAppearanceNotesIfNeeded()
    }

    private func saveAppearanceNotesIfNeeded() {
        let cleaned = appearanceNotesDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned != character.visualDescription else { return }
        character.visualDescription = cleaned
        character.markModified()
        do {
            try modelContext.saveOrRollback()
            appearanceNotesDraft = character.visualDescription
        } catch {
            appearanceNotesDraft = character.visualDescription
            let message = "Character Profiler could not save the appearance notes. \(error.localizedDescription)"
            if isDisappearing {
                reportPersistenceFailure(message)
            } else {
                errorMessage = message
            }
        }
    }

    private func saveContext() {
        do {
            try modelContext.saveOrRollback()
        } catch {
            errorMessage = "Character Profiler could not save the visual changes. \(error.localizedDescription)"
        }
    }
}

@available(iOS 18.1, *)
private struct VisualReferenceEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let reference: CharacterReferenceImage
    let character: CharacterProfile

    @State private var label: String
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?

    init(reference: CharacterReferenceImage, character: CharacterProfile) {
        self.reference = reference
        self.character = character
        _label = State(initialValue: reference.label)
    }

    private var currentIndex: Int? {
        character.sortedReferenceImages.firstIndex { $0.id == reference.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reference") {
                    if let image = UIImage(data: reference.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 360)
                            .frame(maxWidth: .infinity)
                    }
                    TextField("Label", text: $label)
                }

                Section("Order") {
                    HStack {
                        Button("Move Earlier", systemImage: "arrow.left") {
                            VisualReferenceOrdering.move(reference, by: -1, in: character)
                            character.markModified()
                            save()
                        }
                        .disabled(currentIndex == 0)
                        Spacer()
                        Button("Move Later", systemImage: "arrow.right") {
                            VisualReferenceOrdering.move(reference, by: 1, in: character)
                            character.markModified()
                            save()
                        }
                        .disabled(currentIndex == character.referenceImages.count - 1)
                    }
                }

                Section {
                    Button("Delete Reference", systemImage: "trash", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background { CharacterProfilerBackdrop() }
            .navigationTitle("Reference Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
                        reference.label = trimmed.isEmpty ? "Reference" : trimmed
                        character.markModified()
                        save()
                        if errorMessage == nil { dismiss() }
                    }
                }
            }
            .confirmationDialog("Delete this reference image?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Reference", role: .destructive) { deleteReference() }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Reference Image", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func deleteReference() {
        character.referenceImages.removeAll { $0.id == reference.id }
        modelContext.delete(reference)
        VisualReferenceOrdering.normalize(in: character)
        character.markModified()
        save()
        if errorMessage == nil { dismiss() }
    }

    private func save() {
        do {
            try modelContext.saveOrRollback()
        } catch {
            errorMessage = "Character Profiler could not save the reference changes. \(error.localizedDescription)"
        }
    }
}
#else
@available(iOS 18.1, *)
struct CharacterVisualWorkspaceView: View {
    let character: CharacterProfile
    var body: some View { VisualFeatureUnavailableView() }
}
#endif
