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

struct CharacterPrompt: Identifiable, Hashable {
    let id: String
    let category: PromptCategory
    let question: String
    let genres: [StoryGenre]

    init(id: String, category: PromptCategory, question: String, genres: [StoryGenre] = []) {
        self.id = id
        self.category = category
        self.question = question
        self.genres = genres
    }

    func applies(to genre: StoryGenre) -> Bool { genres.isEmpty || genres.contains(genre) }
}

enum PromptEngine {
    static func suggestions(for character: CharacterProfile, in project: StoryProject, limit: Int = 8) -> [CharacterPrompt] {
        let answered = Set(character.promptResponses.filter { !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.map(\.promptID))
        var candidates = adaptivePrompts(for: character, genre: project.genre)
        candidates += catalogue.filter { $0.applies(to: project.genre) }
        var seen = Set<String>()
        return candidates.filter { !answered.contains($0.id) && seen.insert($0.id).inserted }.prefix(limit).map { $0 }
    }

    static func savedAnswers(for character: CharacterProfile) -> [PromptResponse] {
        character.promptResponses.filter { !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.sorted { $0.updatedAt > $1.updatedAt }
    }

    private static func adaptivePrompts(for character: CharacterProfile, genre: StoryGenre) -> [CharacterPrompt] {
        var result: [CharacterPrompt] = []
        let corpus = (character.summary + " " + character.sections.flatMap(\.fields).map(\.value).joined(separator: " ") + " " + character.promptResponses.map(\.answer).joined(separator: " ")).lowercased()
        if character.lifeEvents.contains(where: { $0.kind == .trauma || $0.kind == .loss }) {
            result += [
                CharacterPrompt(id: "adaptive.after-trauma", category: .trauma, question: "What happens when something reminds them of the painful event?"),
                CharacterPrompt(id: "adaptive.trauma-visible", category: .relationships, question: "Who can tell that this past event still affects them?")
            ]
        }
        if !character.allRelationships.isEmpty {
            result.append(CharacterPrompt(id: "adaptive.relationship-pressure", category: .relationships, question: "Which relationship is most likely to fracture under story pressure, and why?"))
        }
        if genre == .fantasy && (corpus.contains("magic") || corpus.contains("spell")) {
            result.append(CharacterPrompt(id: "adaptive.magic-cost", category: .world, question: "What personal cost or temptation comes with their relationship to magic?", genres: [.fantasy]))
        }
        if corpus.contains("tavern") || corpus.contains("drink") || corpus.contains("bar") {
            result.append(CharacterPrompt(id: "adaptive.tavern-behaviour", category: .lifestyle, question: "In a crowded drinking place, do they become louder, guarded, flirtatious, watchful, or leave early?"))
        }
        return result
    }

    static let catalogue: [CharacterPrompt] = foundation + fantasy + scienceFiction + romance + mysteryThriller + horror + historical + contemporary + adventureCrime + youngAdult

    private static let foundation: [CharacterPrompt] = [
        CharacterPrompt(id: "foundation.first-impression", category: .appearance, question: "What is the first thing a stranger notices about them?"),
        CharacterPrompt(id: "foundation.private-self", category: .personality, question: "How are they different when nobody is watching?"),
        CharacterPrompt(id: "foundation.want", category: .motivation, question: "What do they want badly enough to make a poor decision for it?"),
        CharacterPrompt(id: "foundation.need", category: .motivation, question: "What do they actually need, even if they would reject the idea?"),
        CharacterPrompt(id: "foundation.fear", category: .personality, question: "Which fear most strongly shapes their everyday behaviour?"),
        CharacterPrompt(id: "foundation.self-lie", category: .secrets, question: "What lie do they tell themselves?"),
        CharacterPrompt(id: "foundation.childhood", category: .background, question: "What childhood experience still influences their decisions?"),
        CharacterPrompt(id: "foundation.conflict-style", category: .conflict, question: "When confronted, do they fight, charm, negotiate, freeze, flee or plan revenge?"),
        CharacterPrompt(id: "foundation.home", category: .lifestyle, question: "What does their living space reveal that their public persona does not?"),
        CharacterPrompt(id: "foundation.breaking-point", category: .conflict, question: "What could push them to do something they normally consider unforgivable?")
    ]

    private static let fantasy: [CharacterPrompt] = [
        CharacterPrompt(id: "fantasy.tavern", category: .lifestyle, question: "At the end of a long day, would they rather drink in a crowded tavern, sit quietly by the fire, or explore beyond the walls? Why?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.adventure", category: .motivation, question: "What would make them leave safety behind and go adventuring?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.magic", category: .world, question: "How do they feel about magic: wonder, suspicion, envy, fear, duty or simple practicality?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.creatures", category: .world, question: "Which creature of this world fascinates them, and which do they avoid?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.travel", category: .lifestyle, question: "What do they always carry when travelling between settlements?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.faith", category: .world, question: "What do they believe about gods, spirits, fate or prophecy?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.quest", category: .storyRole, question: "What kind of quest would they refuse even if the reward were enormous?", genres: [.fantasy])
    ]

    private static let scienceFiction: [CharacterPrompt] = [
        CharacterPrompt(id: "scifi.tech", category: .world, question: "Which technology do they trust with their life, and which do they refuse to use?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.ai", category: .world, question: "Do they treat artificial intelligence as a tool, a person, a threat, or something else?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.augmentation", category: .identity, question: "Would they alter their body or mind if augmentation offered a major advantage?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.power", category: .conflict, question: "Which corporation, government or institution has power over their life?", genres: [.scienceFiction])
    ]

    private static let romance: [CharacterPrompt] = [
        CharacterPrompt(id: "romance.attraction", category: .relationships, question: "What attracts them immediately, and what kind of attraction grows slowly?", genres: [.romance]),
        CharacterPrompt(id: "romance.guard", category: .relationships, question: "What makes them lower their emotional guard?", genres: [.romance]),
        CharacterPrompt(id: "romance.sabotage", category: .conflict, question: "How might they sabotage a relationship they actually want?", genres: [.romance]),
        CharacterPrompt(id: "romance.future", category: .motivation, question: "What does a satisfying long-term partnership look like to them?", genres: [.romance])
    ]

    private static let mysteryThriller: [CharacterPrompt] = [
        CharacterPrompt(id: "mystery.secret", category: .secrets, question: "What fact about them would make them look suspicious even if they are innocent?", genres: [.mystery, .thriller]),
        CharacterPrompt(id: "mystery.notice", category: .personality, question: "What detail do they notice that most people overlook?", genres: [.mystery, .thriller]),
        CharacterPrompt(id: "thriller.risk", category: .conflict, question: "How much danger will they accept before survival matters more than the mission?", genres: [.thriller])
    ]

    private static let horror: [CharacterPrompt] = [
        CharacterPrompt(id: "horror.fear", category: .trauma, question: "What frightens them before anything supernatural happens?", genres: [.horror]),
        CharacterPrompt(id: "horror.denial", category: .personality, question: "How long would they rationalise impossible events before accepting something is wrong?", genres: [.horror]),
        CharacterPrompt(id: "horror.survival", category: .conflict, question: "Whom would they risk their own life to save?", genres: [.horror])
    ]

    private static let historical: [CharacterPrompt] = [
        CharacterPrompt(id: "historical.class", category: .world, question: "What social class were they born into, and what restrictions does it create?", genres: [.historical]),
        CharacterPrompt(id: "historical.custom", category: .world, question: "Which social custom of their time do they quietly resent?", genres: [.historical]),
        CharacterPrompt(id: "historical.faith", category: .world, question: "How does religion or prevailing moral belief shape their daily decisions?", genres: [.historical])
    ]

    private static let contemporary: [CharacterPrompt] = [
        CharacterPrompt(id: "contemporary.phone", category: .lifestyle, question: "What would someone learn about them from five minutes with their phone?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.weekend", category: .lifestyle, question: "What does an ordinary free Saturday look like for them?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.pressure", category: .conflict, question: "Which ordinary modern pressure gets under their skin most?", genres: [.contemporary])
    ]

    private static let adventureCrime: [CharacterPrompt] = [
        CharacterPrompt(id: "adventure.danger", category: .motivation, question: "Why do they keep going when turning back would be safer?", genres: [.adventure]),
        CharacterPrompt(id: "adventure.team", category: .relationships, question: "What role do they naturally take in a group under pressure?", genres: [.adventure]),
        CharacterPrompt(id: "crime.line", category: .conflict, question: "What crime would they never commit, even if they already break other laws?", genres: [.crime]),
        CharacterPrompt(id: "crime.loyalty", category: .relationships, question: "Would they betray an accomplice to save themselves?", genres: [.crime])
    ]

    private static let youngAdult: [CharacterPrompt] = [
        CharacterPrompt(id: "ya.identity", category: .identity, question: "Which part of their identity are they still trying to define?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.parent", category: .relationships, question: "Which adult do they most want approval from, and which do they resist?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.future", category: .motivation, question: "What future are they afraid will be chosen for them?", genres: [.youngAdult])
    ]
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
