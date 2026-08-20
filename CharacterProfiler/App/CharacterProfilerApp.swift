// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData
import UIKit

enum CharacterProfilerTheme {
    static let ink = Color(red: 0.16, green: 0.12, blue: 0.30)
    static let indigo = Color(red: 0.34, green: 0.28, blue: 0.78)
    static let violet = Color(red: 0.56, green: 0.31, blue: 0.82)
    static let gold = Color(red: 0.88, green: 0.57, blue: 0.18)
    static let rose = Color(red: 0.78, green: 0.28, blue: 0.48)
    static let teal = Color(red: 0.13, green: 0.58, blue: 0.58)

    static let heroGradient = LinearGradient(
        colors: [ink, indigo, violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct CharacterProfilerBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            LinearGradient(
                colors: [
                    CharacterProfilerTheme.indigo.opacity(colorScheme == .dark ? 0.20 : 0.10),
                    CharacterProfilerTheme.gold.opacity(colorScheme == .dark ? 0.08 : 0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(CharacterProfilerTheme.violet.opacity(colorScheme == .dark ? 0.10 : 0.06))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: 150, y: -260)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct CharacterProfilerCardSurface: View {
    let accent: Color
    var prominent = false

    var body: some View {
        RoundedRectangle(cornerRadius: prominent ? 24 : 18, style: .continuous)
            .fill(.thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: prominent ? 24 : 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(prominent ? 0.18 : 0.10), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: prominent ? 24 : 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.42), Color.white.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: accent.opacity(prominent ? 0.16 : 0.09), radius: prominent ? 18 : 10, y: prominent ? 9 : 5)
    }
}

struct CharacterProfilerIconTile: View {
    let systemImage: String
    let accent: Color
    var size: CGFloat = 46

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [accent, accent.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
            )
            .shadow(color: accent.opacity(0.28), radius: 7, y: 4)
            .accessibilityHidden(true)
    }
}

struct CharacterProfilerSectionHeader: View {
    let title: String
    let systemImage: String
    var accent = CharacterProfilerTheme.indigo

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(accent)
            .textCase(nil)
    }
}

private final class ModelContainerLoader: ObservableObject {
    @Published private(set) var result: Result<ModelContainer, Error>

    init() {
        result = Self.openStore()
    }

    func retry() {
        result = Self.openStore()
    }

    private static func openStore() -> Result<ModelContainer, Error> {
        let schema = Schema([
            StoryProject.self,
            CharacterProfile.self,
            ProfileSection.self,
            ProfileField.self,
            LifeEvent.self,
            PromptResponse.self,
            CharacterReferenceImage.self,
            CharacterVisualFrame.self,
            CharacterRelationship.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return .success(try ModelContainer(for: schema, configurations: [configuration]))
        } catch {
            return .failure(error)
        }
    }
}

@main
struct CharacterProfilerApp: App {
    @StateObject private var containerLoader = ModelContainerLoader()
    @State private var persistenceFailureMessage: String?

    var body: some Scene {
        WindowGroup {
            switch containerLoader.result {
            case .success(let modelContainer):
                ProjectListView()
                    .modelContainer(modelContainer)
                    .tint(CharacterProfilerTheme.indigo)
                    .environment(\.reportPersistenceFailure) { message in
                        persistenceFailureMessage = message
                    }
                    .alert("Changes Could Not Be Saved", isPresented: Binding(
                        get: { persistenceFailureMessage != nil },
                        set: { if !$0 { persistenceFailureMessage = nil } }
                    )) {
                        Button("OK", role: .cancel) { persistenceFailureMessage = nil }
                    } message: {
                        Text(persistenceFailureMessage ?? "Unknown persistence error.")
                    }
            case .failure(let error):
                DataStoreUnavailableView(error: error, retry: containerLoader.retry)
            }
        }
    }
}

private struct DataStoreUnavailableView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Story Library Unavailable", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            VStack(spacing: 10) {
                Text("Character Profiler could not open its local story database. The app will not erase or replace the store automatically.")
                Text("You can retry opening the preserved library. If the problem continues, preserve the app's data before reinstalling so the story library can be recovered or inspected.")
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Button("Retry Opening Library", action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
