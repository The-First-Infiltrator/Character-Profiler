// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum ProfileTemplate {
    static var defaultSections: [SectionDraft] {
        [
            SectionDraft(title: "Identity", fields: [
                FieldDraft(label: "Full Name", value: ""), FieldDraft(label: "Species / Ancestry", value: ""),
                FieldDraft(label: "Occupation", value: ""), FieldDraft(label: "Home / Origin", value: "")
            ]),
            SectionDraft(title: "Appearance", fields: [
                FieldDraft(label: "Height", value: ""), FieldDraft(label: "Build", value: ""),
                FieldDraft(label: "Hair", value: ""), FieldDraft(label: "Eyes", value: ""),
                FieldDraft(label: "Clothing / Style", value: ""), FieldDraft(label: "Distinguishing Features", value: "")
            ]),
            SectionDraft(title: "Personality", fields: [
                FieldDraft(label: "Temperament", value: ""), FieldDraft(label: "Strengths", value: ""),
                FieldDraft(label: "Flaws", value: ""), FieldDraft(label: "Fears", value: ""),
                FieldDraft(label: "Values", value: ""), FieldDraft(label: "Habits / Mannerisms", value: "")
            ]),
            SectionDraft(title: "Motivation", fields: [
                FieldDraft(label: "Wants", value: ""), FieldDraft(label: "Needs", value: ""),
                FieldDraft(label: "Biggest Goal", value: ""), FieldDraft(label: "What Stops Them", value: "")
            ]),
            SectionDraft(title: "Background", fields: [
                FieldDraft(label: "Childhood", value: ""), FieldDraft(label: "Education / Training", value: ""),
                FieldDraft(label: "Beliefs", value: ""), FieldDraft(label: "Reputation", value: "")
            ]),
            SectionDraft(title: "Secrets", fields: [
                FieldDraft(label: "Secret", value: ""), FieldDraft(label: "What They Hide From Themselves", value: "")
            ])
        ]
    }
}

enum CharacterImageProcessor {
    static func normalisedJPEGData(from data: Data, maxDimension: CGFloat = 1200) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }
        let scale = min(1, maxDimension / longest)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let rendered = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return rendered.jpegData(compressionQuality: 0.86)
        #else
        return data
        #endif
    }
}
