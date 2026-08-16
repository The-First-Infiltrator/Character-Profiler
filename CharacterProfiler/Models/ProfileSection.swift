// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftData

@Model
final class ProfileSection {
    @Attribute(.unique) var id: UUID
    var title: String
    var sortOrder: Int
    var character: CharacterProfile?

    @Relationship(deleteRule: .cascade, inverse: \ProfileField.section)
    var fields: [ProfileField]

    init(
        id: UUID = UUID(),
        title: String,
        sortOrder: Int = 0,
        character: CharacterProfile? = nil,
        fields: [ProfileField] = []
    ) {
        self.id = id
        self.title = title
        self.sortOrder = sortOrder
        self.character = character
        self.fields = fields
    }

    var sortedFields: [ProfileField] {
        fields.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending
            }
            return $0.sortOrder < $1.sortOrder
        }
    }
}
