// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import SwiftData

// MARK: - History ordering

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

// MARK: - History workspace

struct CharacterTimelinePanel: View {
    @Environment(\.modelContext) private var modelContext
    let character: CharacterProfile
    @State private var showingAdd = false
    @State private var editingEvent: LifeEvent?
    @State private var eventPendingDeletion: LifeEvent?
    @State private var saveErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .font(.title3.bold())
                    .foregroundStyle(CharacterProfilerTheme.teal)
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
                    Circle()
                        .fill(CharacterProfilerTheme.teal.opacity(0.14))
                        .frame(width: 34, height: 34)
                    Image(systemName: event.kind.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CharacterProfilerTheme.teal)
                }
                if index < total - 1 {
                    Rectangle()
                        .fill(CharacterProfilerTheme.teal.opacity(0.28))
                        .frame(width: 2, height: 52)
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
                .background { CharacterProfilerCardSurface(accent: CharacterProfilerTheme.teal) }
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        character.markModified()
        do {
            try modelContext.saveOrRollback()
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
        character.lifeEvents.removeAll { $0.id == event.id }
        modelContext.delete(event)
        LifeEventOrdering.normalize(in: character)
        character.markModified()
        do {
            try modelContext.saveOrRollback()
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
                Section {
                    TextField("Event title", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(LifeEventKind.allCases) { eventKind in
                            Text(eventKind.displayName).tag(eventKind)
                        }
                    }
                    TextField("When / age", text: $whenText)
                } header: {
                    CharacterProfilerSectionHeader(
                        title: "Event",
                        systemImage: "clock.arrow.circlepath",
                        accent: CharacterProfilerTheme.teal
                    )
                }
                Section {
                    TextField("Describe the event", text: $details, axis: .vertical).lineLimit(3...10)
                } header: {
                    CharacterProfilerSectionHeader(
                        title: "What Happened",
                        systemImage: "text.alignleft",
                        accent: CharacterProfilerTheme.indigo
                    )
                }
                Section {
                    TextField("How did it change them?", text: $impact, axis: .vertical).lineLimit(2...8)
                    Text("Impact can influence adaptive Character Guide questions later.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    CharacterProfilerSectionHeader(
                        title: "Lasting Impact",
                        systemImage: "arrow.triangle.branch",
                        accent: CharacterProfilerTheme.gold
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background { CharacterProfilerBackdrop() }
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
        character.markModified()
        do {
            try modelContext.saveOrRollback()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}
