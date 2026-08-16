// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftData

@Model
final class ProfileField {
    @Attribute(.unique) var id: UUID
    var label: String
    var value: String
    var sortOrder: Int
    var section: ProfileSection?

    init(
        id: UUID = UUID(),
        label: String,
        value: String = "",
        sortOrder: Int = 0,
        section: ProfileSection? = nil
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.sortOrder = sortOrder
        self.section = section
    }
}
