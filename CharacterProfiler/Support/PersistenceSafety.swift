// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftData

enum PersistenceSafety {
    /// Executes a persistence commit and guarantees rollback before the error escapes.
    ///
    /// Keeping the transaction primitive injectable lets tests force the failure path without
    /// depending on a particular SQLite/SwiftData failure mode.
    static func commit(save: () throws -> Void, rollback: () -> Void) throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}

extension ModelContext {
    /// Persists the current unit of work or restores the context to its last committed state.
    ///
    /// Character Profiler performs user-visible edits directly in the main SwiftData context.
    /// A failed save must therefore never leave an insert, delete, or edit pending for a later
    /// unrelated save to commit accidentally.
    func saveOrRollback() throws {
        try PersistenceSafety.commit(
            save: { try save() },
            rollback: { rollback() }
        )
    }
}

extension CharacterProfile {
    /// Marks character-scoped author work as recently changed and propagates activity to the story.
    /// Story Library ordering is based on `StoryProject.updatedAt`, so child-record edits must touch
    /// both timestamps to keep the most recently worked-on project at the top of the library.
    func markModified(at date: Date = .now) {
        updatedAt = date
        project?.updatedAt = date
    }
}
