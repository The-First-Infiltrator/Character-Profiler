// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData
import PhotosUI
import UIKit
#if canImport(ImagePlayground)
import ImagePlayground
#endif

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
                    if #available(iOS 18.1, *) { CharacterVisualPanel(character: character) }
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
    @State private var selectedPrompt: CharacterPrompt?
    @State private var answer = ""

    var prompts: [CharacterPrompt] { PromptEngine.suggestions(for: character, in: project, limit: 10) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Character Guide", systemImage: "sparkles").font(.title3.bold())
            Text("Questions change with the story genre and what you have already recorded.").foregroundStyle(.secondary)
            ForEach(prompts) { prompt in
                Button {
                    selectedPrompt = prompt
                    answer = character.response(for: prompt.id)?.answer ?? ""
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(prompt.category.displayName, systemImage: prompt.category.icon).font(.caption.weight(.semibold))
                        Text(prompt.question).foregroundStyle(.primary).multilineTextAlignment(.leading)
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain)
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
        .sheet(item: $selectedPrompt) { prompt in
            NavigationStack {
                Form {
                    Section { Text(prompt.question) }
                    Section("Answer") { TextField("Write what is true for this character", text: $answer, axis: .vertical).lineLimit(4...12) }
                }
                .navigationTitle(prompt.category.displayName)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { selectedPrompt = nil } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let existing = character.response(for: prompt.id) {
                                existing.answer = answer; existing.question = prompt.question; existing.updatedAt = .now
                            } else {
                                let response = PromptResponse(promptID: prompt.id, question: prompt.question, category: prompt.category, answer: answer, character: character)
                                modelContext.insert(response); character.promptResponses.append(response)
                            }
                            character.updatedAt = .now; try? modelContext.save(); selectedPrompt = nil
                        }
                    }
                }
            }
        }
    }
}

private struct CharacterRelationshipsPanel: View {
    @Environment(\.modelContext) private var modelContext
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
                if !family.isEmpty { Text("Family").font(.headline) }
                ForEach(family) { RelationshipRow(character: character, relationship: $0) }
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
            HStack {
                CharacterPortraitView(character: other, size: 42)
                VStack(alignment: .leading) {
                    Text(other.name).font(.headline)
                    Text(relationship.kind(from: character).displayName).font(.subheadline).foregroundStyle(.secondary)
                    if !relationship.notes.isEmpty { Text(relationship.notes).font(.caption).foregroundStyle(.secondary) }
                }
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
    var body: some View {
        NavigationStack {
            Form {
                Picker("Person", selection: $targetID) {
                    Text("Choose a character").tag(Optional<UUID>.none)
                    ForEach(candidates) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("Relationship", selection: $kind) { ForEach(RelationshipKind.allCases) { Text($0.displayName).tag($0) } }
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle("Add Relationship")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let id = targetID, let target = candidates.first(where: { $0.id == id }) else { return }
                        let link = CharacterRelationship(kind: kind, notes: notes, source: character, target: target)
                        modelContext.insert(link); character.outgoingRelationships.append(link); target.incomingRelationships.append(link)
                        try? modelContext.save(); dismiss()
                    }.disabled(targetID == nil)
                }
            }
        }
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

@available(iOS 18.1, *)
private struct CharacterVisualPanel: View {
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingGenerator = false
    @State private var generationAngle: VisualAngle?
    @State private var viewerIndex = 0

    private var sourceImage: Image? {
        if let angle = generationAngle, character.generatedVisualData != nil, let data = character.generatedVisualData, let image = UIImage(data: data) {
            return Image(uiImage: image)
        }
        if let board = referenceBoardImage() { return Image(uiImage: board) }
        if let data = character.profileImageData, let image = UIImage(data: data) { return Image(uiImage: image) }
        return nil
    }

    private var concept: String {
        if let angle = generationAngle { return baseDescription + " " + angle.generationInstruction }
        return baseDescription + " Create a single consistent full-body character reference on a plain unobtrusive background. Do not create a scene."
    }

    private var baseDescription: String {
        var parts = ["Character named \(character.name)."]
        if let project = character.project { parts.append("Genre: \(project.genreDisplayName).") }
        if !character.storyRole.isEmpty { parts.append("Story role: \(character.storyRole).") }
        if !character.summary.isEmpty { parts.append(character.summary) }
        if !character.visualDescription.isEmpty { parts.append("Appearance instructions: \(character.visualDescription)") }
        let fields = character.sections.flatMap { section in section.fields.compactMap { field in
            let value = field.value.trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : "\(field.label): \(value)"
        }}
        if !fields.isEmpty { parts.append("Known appearance/profile facts: " + fields.joined(separator: "; ")) }
        return parts.joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Character Visual Studio", systemImage: "person.crop.rectangle.stack").font(.title3.bold())
            Text("Use reference pictures and the written profile to establish one canonical look, then optionally build eight views for a simple 360° turn-around.").foregroundStyle(.secondary)

            GroupBox("Reference Pictures") {
                VStack(alignment: .leading, spacing: 10) {
                    if character.referenceImages.isEmpty { Text("Add face, full-body, clothing, hair or other visual references.").font(.subheadline).foregroundStyle(.secondary) }
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(character.sortedReferenceImages) { ref in
                                if let image = UIImage(data: ref.imageData) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image).resizable().scaledToFill().frame(width: 105, height: 130).clipShape(RoundedRectangle(cornerRadius: 10))
                                        Button(role: .destructive) { modelContext.delete(ref); try? modelContext.save() } label: { Image(systemName: "xmark.circle.fill").symbolRenderingMode(.palette).foregroundStyle(.white, .black.opacity(0.55)) }.padding(4)
                                    }
                                }
                            }
                        }
                    }
                    if character.referenceImages.count < 6 {
                        PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 6 - character.referenceImages.count, matching: .images) { Label("Add References", systemImage: "photo.on.rectangle.angled") }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Appearance Notes") {
                TextField("Details the pictures do not show—height, build, scars, clothing, equipment, colours…", text: Binding(get: { character.visualDescription }, set: { character.visualDescription = $0; character.updatedAt = .now }), axis: .vertical)
                    .lineLimit(4...10).onSubmit { try? modelContext.save() }
            }

            GroupBox("AI Character") {
                VStack(alignment: .leading, spacing: 12) {
                    if let data = character.generatedVisualData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 420).clipShape(RoundedRectangle(cornerRadius: 14))
                        HStack {
                            Button("Regenerate", systemImage: "sparkles") { generationAngle = nil; showingGenerator = true }
                            Button("Use as Portrait", systemImage: "person.crop.circle") { character.profileImageData = data; try? modelContext.save() }
                        }
                    } else {
                        ContentUnavailableView("No Canonical Visual Yet", systemImage: "person.crop.rectangle.badge.plus", description: Text("Generate one from the profile and your reference pictures."))
                        Button("Create Character Visual", systemImage: "sparkles") { generationAngle = nil; showingGenerator = true }.buttonStyle(.borderedProminent)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("360° Turn-Around") {
                VStack(alignment: .leading, spacing: 12) {
                    if let frame = currentFrame, let image = UIImage(data: frame.imageData) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 420).frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 12).onEnded { value in rotate(by: value.translation.width) })
                        Text("\(frame.angle.displayName) • \(frame.angle.degrees)° — drag left or right to rotate").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("Generate angle views after creating the canonical character. Each frame remains editable and can be regenerated independently.").foregroundStyle(.secondary)
                    }
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(VisualAngle.allCases) { angle in
                                let existing = character.visualFrames.first { $0.angle == angle }
                                Button {
                                    if let existing, let index = character.sortedVisualFrames.firstIndex(where: { $0.id == existing.id }) { viewerIndex = index }
                                    else if character.generatedVisualData != nil { generationAngle = angle; showingGenerator = true }
                                } label: {
                                    VStack(spacing: 4) {
                                        if let existing, let image = UIImage(data: existing.imageData) { Image(uiImage: image).resizable().scaledToFill().frame(width: 72, height: 88).clipShape(RoundedRectangle(cornerRadius: 8)) }
                                        else { RoundedRectangle(cornerRadius: 8).fill(.quaternary).frame(width: 72, height: 88).overlay(Image(systemName: "plus")) }
                                        Text("\(angle.degrees)°").font(.caption2)
                                    }
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onChange(of: selectedPhotos) { _, items in importReferences(items) }
        .imagePlaygroundSheet(isPresented: $showingGenerator, concept: concept, sourceImage: sourceImage) { url in
            guard let data = try? Data(contentsOf: url), let normalised = CharacterImageProcessor.normalisedJPEGData(from: data, maxDimension: 1600) else { return }
            if let angle = generationAngle {
                if let existing = character.visualFrames.first(where: { $0.angle == angle }) { existing.imageData = normalised; existing.generatedAt = .now }
                else { let frame = CharacterVisualFrame(angle: angle, imageData: normalised, character: character); modelContext.insert(frame); character.visualFrames.append(frame) }
            } else { character.generatedVisualData = normalised }
            character.updatedAt = .now; try? modelContext.save(); generationAngle = nil
        }
    }

    private var currentFrame: CharacterVisualFrame? {
        let frames = character.sortedVisualFrames
        guard !frames.isEmpty else { return nil }
        return frames[min(viewerIndex, frames.count - 1)]
    }

    private func rotate(by translation: CGFloat) {
        let frames = character.sortedVisualFrames
        guard frames.count > 1 else { return }
        let step = translation < 0 ? 1 : -1
        viewerIndex = (viewerIndex + step + frames.count) % frames.count
    }

    private func importReferences(_ items: [PhotosPickerItem]) {
        Task {
            for item in items.prefix(max(0, 6 - character.referenceImages.count)) {
                if let data = try? await item.loadTransferable(type: Data.self), let normalised = CharacterImageProcessor.normalisedJPEGData(from: data) {
                    await MainActor.run {
                        let ref = CharacterReferenceImage(label: "Reference \(character.referenceImages.count + 1)", sortOrder: character.referenceImages.count, imageData: normalised, character: character)
                        modelContext.insert(ref); character.referenceImages.append(ref)
                    }
                }
            }
            await MainActor.run { selectedPhotos = []; character.updatedAt = .now; try? modelContext.save() }
        }
    }

    private func referenceBoardImage() -> UIImage? {
        let images = character.sortedReferenceImages.compactMap { UIImage(data: $0.imageData) }
        guard !images.isEmpty else { return nil }
        let canvas = CGSize(width: 1200, height: 1200)
        let cols = images.count == 1 ? 1 : 2
        let rows = Int(ceil(Double(images.count) / Double(cols)))
        let cell = CGSize(width: canvas.width / CGFloat(cols), height: canvas.height / CGFloat(rows))
        return UIGraphicsImageRenderer(size: canvas).image { context in
            UIColor.systemBackground.setFill(); context.fill(CGRect(origin: .zero, size: canvas))
            for (index, image) in images.enumerated() {
                let col = index % cols, row = index / cols
                let rect = CGRect(x: CGFloat(col) * cell.width, y: CGFloat(row) * cell.height, width: cell.width, height: cell.height)
                let scale = min(rect.width / image.size.width, rect.height / image.size.height)
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                image.draw(in: CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height))
            }
        }
    }
}
