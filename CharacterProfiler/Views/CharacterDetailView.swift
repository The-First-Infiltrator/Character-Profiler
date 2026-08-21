// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData
import RealityKit
import QuickLook

/// Character home screen. Heavy workspaces are intentionally separate navigation destinations so
/// the iPhone experience stays readable and each task gets enough room to breathe.
struct CharacterDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteErrorMessage: String?

    private var profileFactCount: Int {
        character.sections.reduce(0) { total, section in
            total + section.fields.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        }
    }

    private var guideAnswerCount: Int {
        character.promptResponses.filter {
            !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
    }

    private var relationshipCount: Int { Set(character.allRelationships.map(\.id)).count }
    private var historyCount: Int { character.lifeEvents.count }
    private var visualAssetCount: Int {
        character.referenceImages.count + character.visualFrames.count
            + (character.profileImageData == nil ? 0 : 1)
            + (character.generatedVisualData == nil ? 0 : 1)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                CharacterHeader(character: character)

                if !character.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(character.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background { CharacterProfilerCardSurface(accent: CharacterProfilerTheme.gold) }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Character Workspace", systemImage: "square.grid.2x2.fill")
                        .font(.title3.bold())
                        .foregroundStyle(CharacterProfilerTheme.indigo)
                    Text("Open the part of this character you want to work on. Each area keeps its own tools and editing flow.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    CharacterProfileWorkspaceView(character: character)
                } label: {
                    CharacterWorkspaceCard(
                        title: "Profile",
                        subtitle: profileFactCount == 0 ? "Build identity, personality and custom facts" : "Review identity and \(profileFactCount) saved fact\(profileFactCount == 1 ? "" : "s")",
                        systemImage: "person.text.rectangle",
                        badge: profileFactCount == 0 ? "Start" : "\(profileFactCount)",
                        accent: CharacterProfilerTheme.indigo
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workspace-profile")

                if let project = character.project {
                    NavigationLink {
                        CharacterGuideWorkspaceView(character: character, project: project)
                    } label: {
                        CharacterWorkspaceCard(
                            title: "Character Guide",
                            subtitle: guideAnswerCount == 0 ? "Answer adaptive development questions" : "Continue development from \(guideAnswerCount) saved answer\(guideAnswerCount == 1 ? "" : "s")",
                            systemImage: "sparkles",
                            badge: guideAnswerCount == 0 ? "Explore" : "\(guideAnswerCount)",
                            accent: CharacterProfilerTheme.gold
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("workspace-guide")

                    NavigationLink {
                        CharacterRelationshipsWorkspaceView(character: character, project: project)
                    } label: {
                        CharacterWorkspaceCard(
                            title: "People & Relationships",
                            subtitle: relationshipCount == 0 ? "Connect family, friends, rivals and partners" : "\(relationshipCount) relationship\(relationshipCount == 1 ? "" : "s") linked to this character",
                            systemImage: "person.2",
                            badge: relationshipCount == 0 ? "Add" : "\(relationshipCount)",
                            accent: CharacterProfilerTheme.rose
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("workspace-relationships")
                } else {
                    CharacterWorkspaceCard(
                        title: "Character Guide",
                        subtitle: "Assign this character to a story to use the Guide",
                        systemImage: "sparkles",
                        badge: "Unavailable",
                        accent: CharacterProfilerTheme.gold
                    )
                    CharacterWorkspaceCard(
                        title: "People & Relationships",
                        subtitle: "Assign this character to a story to link people",
                        systemImage: "person.2",
                        badge: "Unavailable",
                        accent: CharacterProfilerTheme.rose
                    )
                }

                NavigationLink {
                    CharacterHistoryWorkspaceView(character: character)
                } label: {
                    CharacterWorkspaceCard(
                        title: "History",
                        subtitle: historyCount == 0 ? "Record the events that shaped this character" : "\(historyCount) life event\(historyCount == 1 ? "" : "s") in chronological order",
                        systemImage: "clock.arrow.circlepath",
                        badge: historyCount == 0 ? "Add" : "\(historyCount)",
                        accent: CharacterProfilerTheme.teal
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workspace-history")
                .accessibilityLabel("History")

                NavigationLink {
                    CharacterVisualWorkspaceScreen(character: character)
                } label: {
                    CharacterWorkspaceCard(
                        title: "Visual Studio",
                        subtitle: visualAssetCount == 0 ? "Build 2D concept art or a real rotatable 3D reconstruction" : "Work with \(visualAssetCount) portrait, reference or generated asset\(visualAssetCount == 1 ? "" : "s"), plus 3D reconstruction",
                        systemImage: "person.crop.rectangle.stack",
                        badge: visualAssetCount == 0 ? "Open" : "\(visualAssetCount)",
                        accent: CharacterProfilerTheme.violet
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workspace-visual")
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background { CharacterProfilerBackdrop() }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if character.project != nil {
                Menu {
                    Button { showingEditor = true } label: {
                        Label("Edit Character", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                        Label("Delete Character", systemImage: "trash")
                    }
                } label: {
                    Label("Character Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let project = character.project {
                NavigationStack { CharacterEditorView(project: project, character: character) }
            }
        }
        .confirmationDialog(
            "Delete Character?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Character Permanently", role: .destructive) { deleteCharacter() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(characterDeletionMessage)
        }
        .alert("Character Could Not Be Deleted", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "Unknown delete error.")
        }
    }

    private var characterDeletionMessage: String {
        let answerCount = guideAnswerCount
        return "This permanently deletes \(character.displayName) and removes \(relationshipCount) linked relationship\(relationshipCount == 1 ? "" : "s"), \(historyCount) history entr\(historyCount == 1 ? "y" : "ies"), \(answerCount) Guide answer\(answerCount == 1 ? "" : "s"), and \(visualAssetCount) visual asset\(visualAssetCount == 1 ? "" : "s"). Export the story backup first if you may need this character again."
    }

    private func deleteCharacter() {
        let project = character.project
        modelContext.delete(character)
        project?.updatedAt = .now
        do {
            try modelContext.saveOrRollback()
            dismiss()
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }
}

private struct CharacterHeader: View {
    let character: CharacterProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("CHARACTER DOSSIER", systemImage: "person.text.rectangle.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(CharacterProfilerTheme.gold)

            HStack(alignment: .center, spacing: 16) {
                CharacterPortraitView(character: character, size: 96)
                VStack(alignment: .leading, spacing: 7) {
                    Text(character.displayName)
                        .font(.title2.bold())
                        .lineLimit(2)
                    if !character.storyRole.isEmpty {
                        Text(character.storyRole)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.76))
                    }
                    HStack(spacing: 10) {
                        if !character.ageText.isEmpty {
                            Label(character.ageText, systemImage: "birthday.cake")
                        }
                        if !character.pronouns.isEmpty { Text(character.pronouns) }
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.68))
                    ProgressView(value: character.completionScore)
                        .tint(CharacterProfilerTheme.gold)
                        .accessibilityLabel("Character development")
                        .accessibilityValue("\(Int(character.completionScore * 100)) percent")
                    Text("\(Int(character.completionScore * 100))% developed")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CharacterProfilerTheme.gold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(CharacterProfilerTheme.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
        .shadow(color: CharacterProfilerTheme.ink.opacity(0.24), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("character-dossier-hero")
    }
}

private struct CharacterWorkspaceCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let badge: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            CharacterProfilerIconTile(systemImage: systemImage, accent: accent, size: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Text(badge)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.11), in: Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { CharacterProfilerCardSurface(accent: accent) }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CharacterProfileWorkspaceView: View {
    let character: CharacterProfile

    var body: some View {
        ScrollView {
            CharacterProfilePanel(character: character)
                .padding()
        }
        .background { CharacterProfilerBackdrop() }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterGuideWorkspaceView: View {
    let character: CharacterProfile
    let project: StoryProject

    var body: some View {
        ScrollView {
            CharacterGuidePanel(character: character, project: project)
                .padding()
        }
        .background { CharacterProfilerBackdrop() }
        .navigationTitle("Character Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterRelationshipsWorkspaceView: View {
    let character: CharacterProfile
    let project: StoryProject

    var body: some View {
        ScrollView {
            CharacterRelationshipsPanel(character: character, project: project)
                .padding()
        }
        .background { CharacterProfilerBackdrop() }
        .navigationTitle("People")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterHistoryWorkspaceView: View {
    let character: CharacterProfile

    var body: some View {
        ScrollView {
            CharacterTimelinePanel(character: character)
                .padding()
        }
        .background { CharacterProfilerBackdrop() }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CharacterVisualWorkspaceScreen: View {
    let character: CharacterProfile

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Character3DHeadWorkspaceView(character: character)

                Group {
                    if #available(iOS 18.1, *) {
                        CharacterVisualWorkspaceView(character: character)
                    } else {
                        VisualFeatureUnavailableView()
                    }
                }
            }
            .padding()
        }
        .background { CharacterProfilerBackdrop() }
        .navigationTitle("Visual Studio")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct Character3DHeadWorkspaceView: View {
    let character: CharacterProfile

    @State private var isGenerating = false
    @State private var progress = 0.0
    @State private var statusText = "Ready"
    @State private var modelURL: URL?
    @State private var showingPreview = false
    @State private var errorMessage: String?

    private var sourceImageData: [Data] {
        var result: [Data] = []
        if let portrait = character.profileImageData { result.append(portrait) }
        result.append(contentsOf: character.sortedReferenceImages.map(\.imageData))
        return result
    }

    var body: some View {
        GroupBox("3D Head Reconstruction") {
            VStack(alignment: .leading, spacing: 12) {
                Label("Real 3D geometry", systemImage: "cube.transparent")
                    .font(.subheadline.weight(.semibold))

                Text("Builds an actual USDZ model from the character photographs with RealityKit photogrammetry. The result is continuously rotatable; it is not a stack of generated 2D angle pictures.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(sourceImageData.count) source image\(sourceImageData.count == 1 ? "" : "s") available")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isGenerating {
                    ProgressView(value: progress)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button(modelURL == nil ? "Generate 3D Head" : "Regenerate 3D Head", systemImage: "cube") {
                        generateModel()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating || sourceImageData.count < 3 || !PhotogrammetrySession.isSupported)

                    if modelURL != nil {
                        Button("Open Rotatable Model", systemImage: "view.3d") {
                            showingPreview = true
                        }
                        .disabled(isGenerating)
                    }
                }

                if sourceImageData.count < 3 {
                    Label("Add at least three clear photographs of the same person from different angles before reconstructing.", systemImage: "photo.stack")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !PhotogrammetrySession.isSupported {
                    Label("This device does not support RealityKit photogrammetry. The 2D Visual Studio remains available below.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if sourceImageData.count < 8 {
                    Label("Three images can be attempted, but more overlapping face angles generally produce a much stronger reconstruction.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $showingPreview) {
            if let modelURL {
                NavigationStack {
                    QuickLookModelPreview(url: modelURL)
                        .ignoresSafeArea(edges: .bottom)
                        .navigationTitle("3D Head")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showingPreview = false }
                            }
                        }
                }
            }
        }
        .alert("3D Reconstruction", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown reconstruction error.")
        }
    }

    private func generateModel() {
        guard !isGenerating else { return }
        let images = sourceImageData
        guard images.count >= 3 else {
            errorMessage = "At least three photographs of the same person are required."
            return
        }
        guard PhotogrammetrySession.isSupported else {
            errorMessage = "RealityKit photogrammetry is not supported on this device."
            return
        }

        isGenerating = true
        progress = 0
        statusText = "Preparing source photographs…"

        Task {
            do {
                let manager = FileManager.default
                let root = manager.temporaryDirectory
                    .appendingPathComponent("CharacterProfiler-3D-\(UUID().uuidString)", isDirectory: true)
                let input = root.appendingPathComponent("Input", isDirectory: true)
                try manager.createDirectory(at: input, withIntermediateDirectories: true)

                for (index, data) in images.enumerated() {
                    let url = input.appendingPathComponent(String(format: "reference-%02d.jpg", index + 1))
                    try data.write(to: url, options: .atomic)
                }

                let output = root.appendingPathComponent("character-head.usdz")
                let session = try PhotogrammetrySession(input: input)
                let request = PhotogrammetrySession.Request.modelFile(
                    url: output,
                    detail: .medium,
                    geometry: nil
                )

                try session.process(requests: [request])
                var completedURL: URL?

                for try await event in session.outputs {
                    switch event {
                    case .inputComplete:
                        await MainActor.run { statusText = "Photographs matched. Reconstructing geometry…" }
                    case .requestProgress(_, let fractionComplete):
                        await MainActor.run {
                            progress = fractionComplete
                            statusText = "Building 3D model… \(Int(fractionComplete * 100))%"
                        }
                    case .requestComplete(_, let result):
                        if case .modelFile(let url) = result {
                            completedURL = url
                        }
                    case .invalidSample(_, let reason):
                        await MainActor.run { statusText = "A source image was rejected: \(reason)" }
                    case .skippedSample:
                        await MainActor.run { statusText = "A source image could not be matched; continuing with the remaining views…" }
                    case .stitchingIncomplete:
                        await MainActor.run { statusText = "The photo set only partially matched; finishing the best available reconstruction…" }
                    case .requestError(_, let error):
                        throw error
                    case .processingComplete:
                        break
                    default:
                        break
                    }
                }

                guard let completedURL else {
                    throw Character3DReconstructionError.noModelProduced
                }

                await MainActor.run {
                    modelURL = completedURL
                    progress = 1
                    statusText = "3D reconstruction complete"
                    isGenerating = false
                    showingPreview = true
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    progress = 0
                    statusText = "Reconstruction failed"
                    errorMessage = "The photographs could not be reconstructed into a reliable 3D model. Try clearer, overlapping views of the same head from more angles. \(error.localizedDescription)"
                }
            }
        }
    }
}

private enum Character3DReconstructionError: LocalizedError {
    case noModelProduced

    var errorDescription: String? {
        switch self {
        case .noModelProduced:
            return "RealityKit finished without producing a model file."
        }
    }
}

private struct QuickLookModelPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.url = url
        uiViewController.reloadData()
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

private struct CharacterProfilePanel: View {
    let character: CharacterProfile

    private var populatedSections: [ProfileSection] {
        character.sortedSections.filter { section in
            section.fields.contains { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !character.summary.isEmpty {
                Text(character.summary)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if populatedSections.isEmpty && character.summary.isEmpty {
                ContentUnavailableView(
                    "Profile Is Still Empty",
                    systemImage: "person.text.rectangle",
                    description: Text("Use Edit Character to add identity, profile sections and facts.")
                )
            } else {
                ForEach(populatedSections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.headline)
                        ForEach(section.sortedFields) { field in
                            if !field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(field.label)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                    Text(field.value)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { CharacterProfilerCardSurface(accent: CharacterProfilerTheme.indigo) }
                }
            }
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
