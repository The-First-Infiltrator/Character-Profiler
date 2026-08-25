// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftUI
import RealityKit
import QuickLook

/// Optional RealityKit photogrammetry workspace.
///
/// Reconstruction is deliberately temporary presentation state: it reads existing
/// portrait/reference images, writes only to an isolated temporary directory and
/// never mutates SwiftData or archive-v1 data. Device capability, minimum input and
/// cancellation remain explicit user-visible boundaries.
struct Character3DHeadWorkspaceView: View {
    let character: CharacterProfile

    @State private var isGenerating = false
    @State private var progress = 0.0
    @State private var statusText = "Ready"
    @State private var modelURL: URL?
    @State private var showingPreview = false
    @State private var errorMessage: String?
    @State private var activeSession: PhotogrammetrySession?

    private var sourceImageData: [Data] {
        var result: [Data] = []
        if let portrait = character.profileImageData { result.append(portrait) }
        result.append(contentsOf: character.sortedReferenceImages.map(\.imageData))
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                CharacterProfilerIconTile(
                    systemImage: "cube.transparent",
                    accent: CharacterProfilerTheme.violet,
                    size: 46
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text("3D Head Reconstruction")
                        .font(.headline)
                    Text("Real rotatable geometry from your reference photographs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text("\(sourceImageData.count) PHOTO\(sourceImageData.count == 1 ? "" : "S")")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CharacterProfilerTheme.violet)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(CharacterProfilerTheme.violet.opacity(0.11), in: Capsule())
            }

            Text("Build an actual USDZ model with RealityKit photogrammetry. A successful result rotates continuously in 3D instead of switching between generated angle pictures.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Label(
                "Temporary preview: the reconstructed USDZ is not yet stored in this character or included in project backups.",
                systemImage: "externaldrive.badge.exclamationmark"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CharacterProfilerTheme.gold.opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Reconstruction readiness")
                    .font(.subheadline.weight(.semibold))
                ReconstructionReadinessRow(
                    title: "Minimum source set",
                    detail: sourceImageData.count >= 3 ? "At least 3 photos available" : "Add \(3 - sourceImageData.count) more photo\(3 - sourceImageData.count == 1 ? "" : "s")",
                    isReady: sourceImageData.count >= 3
                )
                ReconstructionReadinessRow(
                    title: "Stronger overlap",
                    detail: sourceImageData.count >= 8 ? "8+ views available" : "8+ overlapping angles recommended",
                    isReady: sourceImageData.count >= 8
                )
                ReconstructionReadinessRow(
                    title: "Device support",
                    detail: PhotogrammetrySession.isSupported ? "RealityKit reconstruction available" : "This device cannot run photogrammetry",
                    isReady: PhotogrammetrySession.isSupported
                )
            }

            if isGenerating {
                VStack(alignment: .leading, spacing: 7) {
                    ProgressView(value: progress)
                        .tint(CharacterProfilerTheme.violet)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { reconstructionActions }
                VStack(alignment: .leading, spacing: 10) { reconstructionActions }
            }

            if sourceImageData.count < 3 {
                Label("Add at least three clear photographs of the same person from different angles before reconstructing.", systemImage: "photo.stack")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !PhotogrammetrySession.isSupported {
                Label("This device does not support RealityKit photogrammetry. Switch to 2D Appearance to continue using the visual tools.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if sourceImageData.count < 8 {
                Label("Three images can be attempted; additional overlapping face angles improve reconstruction quality.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { CharacterProfilerCardSurface(accent: CharacterProfilerTheme.violet, prominent: true) }
        .accessibilityIdentifier("three-d-head-reconstruction-card")
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

    @ViewBuilder
    private var reconstructionActions: some View {
        Button(modelURL == nil ? "Generate 3D Head" : "Regenerate 3D Head", systemImage: "cube") {
            generateModel()
        }
        .buttonStyle(.borderedProminent)
        .tint(CharacterProfilerTheme.violet)
        .disabled(isGenerating || sourceImageData.count < 3 || !PhotogrammetrySession.isSupported)

        if isGenerating {
            Button("Cancel Reconstruction", systemImage: "xmark.circle", role: .destructive) {
                cancelReconstruction()
            }
            .buttonStyle(.bordered)
        } else if modelURL != nil {
            Button("Open Model", systemImage: "view.3d") {
                showingPreview = true
            }
            .buttonStyle(.bordered)
            .tint(CharacterProfilerTheme.violet)
        }
    }

    private func cancelReconstruction() {
        activeSession?.cancel()
        statusText = "Cancelling reconstruction…"
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
                await MainActor.run { activeSession = session }
                let request = PhotogrammetrySession.Request.modelFile(
                    url: output,
                    detail: .reduced,
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
                    case .processingCancelled:
                        await MainActor.run {
                            activeSession = nil
                            isGenerating = false
                            progress = 0
                            statusText = "Reconstruction cancelled"
                        }
                        return
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
                    activeSession = nil
                    modelURL = completedURL
                    progress = 1
                    statusText = "3D reconstruction complete"
                    isGenerating = false
                    showingPreview = true
                }
            } catch {
                await MainActor.run {
                    activeSession = nil
                    isGenerating = false
                    progress = 0
                    statusText = "Reconstruction failed"
                    errorMessage = "The photographs could not be reconstructed into a reliable 3D model. Try clearer, overlapping views of the same head from more angles. \(error.localizedDescription)"
                }
            }
        }
    }
}

private struct ReconstructionReadinessRow: View {
    let title: String
    let detail: String
    let isReady: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isReady ? CharacterProfilerTheme.teal : .secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
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
