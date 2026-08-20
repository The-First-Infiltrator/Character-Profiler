// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

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

    func applies(to genre: StoryGenre) -> Bool {
        genres.isEmpty || genres.contains(genre)
    }
}

struct GuideSuggestion: Identifiable, Hashable {
    let prompt: CharacterPrompt
    let reason: String
    let score: Int

    var id: String { prompt.id }
    var category: PromptCategory { prompt.category }
    var question: String { prompt.question }
}

enum PromptEngine {
    /// Guide scores are ordinal editorial priorities rather than probabilities. Catalogue prompts
    /// occupy a lower band and receive development-gap boosts; adaptive prompts live in a higher
    /// evidence-driven band so a concrete fact in the character record can outrank generic prompts.
    private enum ScoringPolicy {
        static let genericCatalogueBase = 40
        static let genreSpecificCatalogueBase = 58
        static let emptyCategoryBoost = 24
        static let lightlyDevelopedBoost = 14
        static let moderatelyDevelopedBoost = 6
        static let lightlyDevelopedUpperBound = 2
        static let moderatelyDevelopedUpperBound = 4

        static let answeredPromptDepth = 2
        static let identityFactDepth = 1
        static let storyRoleDepth = 2
        static let summaryDepth = 1
        static let relationshipDepthCap = 4
        static let lifeEventBackgroundDepth = 1
        static let traumaOrLossDepth = 2
        static let conflictEventDepth = 1
        static let secretEventDepth = 1
        static let populatedFieldDepth = 1

        static let diversityCategoryTarget = 6
        static let perCategorySelectionCap = 2

        // Adaptive values intentionally sit above the maximum catalogue score (82). Differences
        // within this band keep the existing evidence-strength ordering stable and deterministic.
        static let afterTrauma = 112
        static let traumaVisible = 106
        static let traumaCoping = 101
        static let relationshipPressure = 108
        static let relationshipBlindspot = 99
        static let familyPattern = 103
        static let eventChain = 96
        static let roleContradiction = 98
        static let magicCost = 110
        static let magicLimit = 104
        static let tavernBehaviour = 102
        static let afterBattle = 107
        static let violenceLine = 103
        static let secretPressure = 105
        static let faithTest = 102
        static let moneyReflex = 98
        static let familyExpectation = 101
        static let relationshipPattern = 100
        static let revengeEndpoint = 109
    }

    static func suggestions(for character: CharacterProfile, in project: StoryProject, limit: Int = 8) -> [CharacterPrompt] {
        detailedSuggestions(for: character, in: project, limit: limit).map(\.prompt)
    }

    static func detailedSuggestions(for character: CharacterProfile, in project: StoryProject, limit: Int = 8) -> [GuideSuggestion] {
        guard limit > 0 else { return [] }

        let answeredIDs = Set(
            character.promptResponses
                .filter { !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map(\.promptID)
        )
        let categoryDepth = developmentDepths(for: character)
        var candidates = adaptiveSuggestions(for: character, in: project)

        for prompt in catalogue where prompt.applies(to: project.genre) && !answeredIDs.contains(prompt.id) {
            let depth = categoryDepth[prompt.category, default: 0]
            let isGenreSpecific = !prompt.genres.isEmpty
            var score = isGenreSpecific ? ScoringPolicy.genreSpecificCatalogueBase : ScoringPolicy.genericCatalogueBase
            if depth == 0 { score += ScoringPolicy.emptyCategoryBoost }
            else if depth <= ScoringPolicy.lightlyDevelopedUpperBound { score += ScoringPolicy.lightlyDevelopedBoost }
            else if depth <= ScoringPolicy.moderatelyDevelopedUpperBound { score += ScoringPolicy.moderatelyDevelopedBoost }

            let reason: String
            if isGenreSpecific && depth <= ScoringPolicy.lightlyDevelopedUpperBound {
                reason = "Because this is a \(project.genreDisplayName) story and \(prompt.category.displayName.lowercased()) is still lightly developed."
            } else if isGenreSpecific {
                reason = "Because this is a \(project.genreDisplayName) story."
            } else if depth == 0 {
                reason = "Because \(prompt.category.displayName.lowercased()) has almost no recorded detail yet."
            } else if depth <= ScoringPolicy.lightlyDevelopedUpperBound {
                reason = "Because \(prompt.category.displayName.lowercased()) is still one of the less-developed parts of this character."
            } else {
                reason = "To test and deepen another side of the character."
            }
            candidates.append(GuideSuggestion(prompt: prompt, reason: reason, score: score))
        }

        let unique = bestUniqueCandidates(candidates.filter { !answeredIDs.contains($0.id) })
        return balancedSelection(from: unique, limit: limit)
    }

    static func savedAnswers(for character: CharacterProfile) -> [PromptResponse] {
        character.promptResponses
            .filter { !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    static func developmentDepths(for character: CharacterProfile) -> [PromptCategory: Int] {
        var depth = Dictionary(uniqueKeysWithValues: PromptCategory.allCases.map { ($0, 0) })

        for response in character.promptResponses where !response.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            depth[response.category, default: 0] += ScoringPolicy.answeredPromptDepth
        }

        if !character.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { depth[.identity, default: 0] += ScoringPolicy.identityFactDepth }
        if !character.ageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { depth[.identity, default: 0] += ScoringPolicy.identityFactDepth }
        if !character.pronouns.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { depth[.identity, default: 0] += ScoringPolicy.identityFactDepth }
        if !character.storyRole.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { depth[.storyRole, default: 0] += ScoringPolicy.storyRoleDepth }
        if !character.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            depth[.personality, default: 0] += ScoringPolicy.summaryDepth
            depth[.background, default: 0] += ScoringPolicy.summaryDepth
        }
        if !character.allRelationships.isEmpty {
            depth[.relationships, default: 0] += min(character.allRelationships.count, ScoringPolicy.relationshipDepthCap)
        }

        for event in character.lifeEvents {
            depth[.background, default: 0] += ScoringPolicy.lifeEventBackgroundDepth
            if event.kind == .trauma || event.kind == .loss { depth[.trauma, default: 0] += ScoringPolicy.traumaOrLossDepth }
            if event.kind == .conflict { depth[.conflict, default: 0] += ScoringPolicy.conflictEventDepth }
            if event.kind == .secret { depth[.secrets, default: 0] += ScoringPolicy.secretEventDepth }
        }

        for section in character.sections {
            for field in section.fields {
                let value = field.value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { continue }
                let haystack = (section.title + " " + field.label).lowercased()
                for category in categories(forFieldText: haystack) {
                    depth[category, default: 0] += ScoringPolicy.populatedFieldDepth
                }
            }
        }
        return depth
    }

    private static func categories(forFieldText text: String) -> Set<PromptCategory> {
        var result: Set<PromptCategory> = []
        let mappings: [(PromptCategory, [String])] = [
            (.identity, ["identity", "name", "species", "ancestry", "occupation", "origin", "age", "pronoun"]),
            (.appearance, ["appearance", "height", "build", "hair", "eyes", "clothing", "style", "feature", "scar", "face"]),
            (.personality, ["personality", "temperament", "strength", "flaw", "fear", "value", "habit", "manner"]),
            (.background, ["background", "childhood", "education", "training", "reputation", "past", "history"]),
            (.motivation, ["motivation", "want", "need", "goal", "ambition", "desire"]),
            (.conflict, ["conflict", "stop", "weakness", "enemy", "obstacle"]),
            (.world, ["belief", "faith", "religion", "culture", "magic", "technology", "politic", "world"]),
            (.lifestyle, ["home", "food", "drink", "routine", "hobby", "sleep", "money", "travel"]),
            (.secrets, ["secret", "hide", "shame", "lie"]),
            (.relationships, ["family", "friend", "relationship", "partner", "parent", "sibling"]),
            (.storyRole, ["role", "arc", "story"])
        ]
        for (category, terms) in mappings where terms.contains(where: { text.contains($0) }) {
            result.insert(category)
        }
        return result
    }

    private static func adaptiveSuggestions(for character: CharacterProfile, in project: StoryProject) -> [GuideSuggestion] {
        var result: [GuideSuggestion] = []
        let corpus = searchableCorpus(for: character)

        if character.lifeEvents.contains(where: { $0.kind == .trauma || $0.kind == .loss }) {
            result += [
                adaptive("adaptive.after-trauma", .trauma, "What happens when something unexpectedly reminds them of the painful event?", "Because their history includes trauma or loss.", ScoringPolicy.afterTrauma),
                adaptive("adaptive.trauma-visible", .relationships, "Who notices the lasting effect first, and what gives it away?", "Because a recorded painful event can affect how other characters read them.", ScoringPolicy.traumaVisible),
                adaptive("adaptive.trauma-coping", .lifestyle, "What ordinary habit do they use to keep difficult memories or feelings manageable?", "Because their history includes trauma or loss, and coping often appears in everyday behaviour.", ScoringPolicy.traumaCoping)
            ]
        }

        if !character.allRelationships.isEmpty {
            result += [
                adaptive("adaptive.relationship-pressure", .relationships, "Which relationship is most likely to fracture under story pressure, and why?", "Because this character already has linked relationships.", ScoringPolicy.relationshipPressure),
                adaptive("adaptive.relationship-blindspot", .relationships, "Which person understands them better than they realise?", "Because existing relationships can reveal blind spots in how the character sees themselves.", ScoringPolicy.relationshipBlindspot)
            ]
        }

        if character.allRelationships.contains(where: { $0.kind(from: character).isFamily }) {
            result.append(adaptive("adaptive.family-pattern", .background, "Which family pattern are they repeating, and which one are they determined to break?", "Because this character has recorded family relationships.", ScoringPolicy.familyPattern))
        }
        if character.lifeEvents.count >= 2 {
            result.append(adaptive("adaptive.event-chain", .background, "Which earlier life event changed the meaning of a later one for them?", "Because their history now contains multiple formative events.", ScoringPolicy.eventChain))
        }
        if !character.storyRole.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.append(adaptive("adaptive.role-contradiction", .storyRole, "What part of their personality makes them unexpectedly bad at—or resistant to—the role the story gives them?", "Because their story role is recorded as “\(character.storyRole)”.", ScoringPolicy.roleContradiction))
        }

        if project.genre == .fantasy && corpus.containsAny(["magic", "spell", "mage", "wizard", "sorcery", "witch"]) {
            result += [
                adaptive("adaptive.magic-cost", .world, "What personal cost, temptation or compromise comes with their relationship to magic?", "Because their recorded details mention magic.", ScoringPolicy.magicCost, [.fantasy]),
                adaptive("adaptive.magic-limit", .conflict, "What magical solution would they refuse even when it would solve an urgent problem?", "Because their recorded details mention magic, which creates an opportunity to define a boundary.", ScoringPolicy.magicLimit, [.fantasy])
            ]
        }
        if corpus.containsAny(["tavern", "drink", "drinking", "bar", "ale", "wine"]) {
            result.append(adaptive("adaptive.tavern-behaviour", .lifestyle, "In a crowded drinking place, do they become louder, guarded, flirtatious, watchful, generous, or eager to leave?", "Because drinking places or alcohol appear in their existing details.", ScoringPolicy.tavernBehaviour))
        }
        if corpus.containsAny(["war", "battle", "soldier", "army", "combat", "mercenary"]) {
            result += [
                adaptive("adaptive.after-battle", .trauma, "What do they do in the first quiet hour after violence ends?", "Because their profile or history mentions war, battle or combat.", ScoringPolicy.afterBattle),
                adaptive("adaptive.violence-line", .conflict, "What kind of violence still feels unacceptable to them, even if violence is part of their life?", "Because combat is already part of their recorded world or history.", ScoringPolicy.violenceLine)
            ]
        }
        if corpus.containsAny(["lie", "secret", "hidden", "hide", "deceive", "deception"]) {
            result.append(adaptive("adaptive.secret-pressure", .secrets, "What situation would make keeping their secret harder than revealing it?", "Because secrecy or deception appears in their existing details.", ScoringPolicy.secretPressure))
        }
        if corpus.containsAny(["faith", "god", "gods", "religion", "church", "temple", "spirit"]) {
            result.append(adaptive("adaptive.faith-test", .world, "What experience could genuinely shake their belief—or make it stronger?", "Because faith or religion appears in their existing details.", ScoringPolicy.faithTest))
        }
        if corpus.containsAny(["money", "poor", "poverty", "rich", "wealth", "debt"]) {
            result.append(adaptive("adaptive.money-reflex", .lifestyle, "What money habit reveals the economic conditions they grew up with?", "Because money, wealth, poverty or debt appears in their recorded details.", ScoringPolicy.moneyReflex))
        }
        if corpus.containsAny(["parent", "mother", "father", "child", "son", "daughter", "sibling", "brother", "sister"]) {
            result.append(adaptive("adaptive.family-expectation", .relationships, "Whose family expectation still has power over them even when that person is absent?", "Because family roles appear in their recorded details.", ScoringPolicy.familyExpectation))
        }
        if corpus.containsAny(["love", "lover", "romance", "relationship", "marriage", "partner"]) {
            result.append(adaptive("adaptive.relationship-pattern", .relationships, "What relationship pattern do they repeat even when they know it ends badly?", "Because romantic or intimate relationships appear in their existing details.", ScoringPolicy.relationshipPattern))
        }
        if corpus.containsAny(["revenge", "vengeance"]) {
            result.append(adaptive("adaptive.revenge-endpoint", .motivation, "If they got perfect revenge tomorrow, what problem would still remain?", "Because revenge appears to be part of their motivation or history.", ScoringPolicy.revengeEndpoint))
        }
        return result
    }

    private static func adaptive(_ id: String, _ category: PromptCategory, _ question: String, _ reason: String, _ score: Int, _ genres: [StoryGenre] = []) -> GuideSuggestion {
        GuideSuggestion(prompt: CharacterPrompt(id: id, category: category, question: question, genres: genres), reason: reason, score: score)
    }

    private static func searchableCorpus(for character: CharacterProfile) -> String {
        [
            character.summary,
            character.storyRole,
            character.visualDescription,
            character.sections.flatMap(\.fields).map { "\($0.label) \($0.value)" }.joined(separator: " "),
            character.promptResponses.map(\.answer).joined(separator: " "),
            character.lifeEvents.map { "\($0.title) \($0.details) \($0.impact)" }.joined(separator: " "),
            character.allRelationships.compactMap { relationship in
                guard let other = relationship.relatedCharacter(to: character) else { return nil }
                return "\(relationship.kind(from: character).displayName) \(other.name) \(relationship.notes)"
            }.joined(separator: " ")
        ].joined(separator: " ").lowercased()
    }

    private static func bestUniqueCandidates(_ candidates: [GuideSuggestion]) -> [GuideSuggestion] {
        var best: [String: GuideSuggestion] = [:]
        for candidate in candidates {
            if let existing = best[candidate.id], existing.score >= candidate.score { continue }
            best[candidate.id] = candidate
        }
        return best.values.sorted {
            if $0.score == $1.score { return $0.id < $1.id }
            return $0.score > $1.score
        }
    }

    private static func balancedSelection(from candidates: [GuideSuggestion], limit: Int) -> [GuideSuggestion] {
        guard !candidates.isEmpty else { return [] }
        var remaining = candidates
        var selected: [GuideSuggestion] = []
        var usedCategories: Set<PromptCategory> = []
        let diversityTarget = min(limit, ScoringPolicy.diversityCategoryTarget)

        while selected.count < diversityTarget {
            guard let index = remaining.firstIndex(where: { !usedCategories.contains($0.category) }) else { break }
            let candidate = remaining.remove(at: index)
            selected.append(candidate)
            usedCategories.insert(candidate.category)
        }

        var categoryCounts = Dictionary(grouping: selected, by: \.category).mapValues { $0.count }
        while selected.count < limit && !remaining.isEmpty {
            if let index = remaining.firstIndex(where: { categoryCounts[$0.category, default: 0] < ScoringPolicy.perCategorySelectionCap }) {
                let candidate = remaining.remove(at: index)
                selected.append(candidate)
                categoryCounts[candidate.category, default: 0] += 1
            } else {
                selected.append(remaining.removeFirst())
            }
        }
        return selected
    }

    static let catalogue: [CharacterPrompt] = foundation + fantasy + scienceFiction + romance + mysteryThriller + horror + historical + contemporary + adventureCrime + youngAdult

    private static let foundation: [CharacterPrompt] = [
        CharacterPrompt(id: "foundation.first-impression", category: .appearance, question: "What is the first thing a stranger notices about them?"),
        CharacterPrompt(id: "foundation.body-language", category: .appearance, question: "What does their body language reveal before they speak?"),
        CharacterPrompt(id: "foundation.presentation", category: .appearance, question: "Which part of their appearance is carefully controlled, and which part do they neglect?"),
        CharacterPrompt(id: "foundation.private-self", category: .personality, question: "How are they different when nobody is watching?"),
        CharacterPrompt(id: "foundation.fear", category: .personality, question: "Which fear most strongly shapes their everyday behaviour?"),
        CharacterPrompt(id: "foundation.pride", category: .personality, question: "What are they quietly proud of but reluctant to admit matters to them?"),
        CharacterPrompt(id: "foundation.irritation", category: .personality, question: "What minor behaviour in other people irritates them far more than it should?"),
        CharacterPrompt(id: "foundation.want", category: .motivation, question: "What do they want badly enough to make a poor decision for it?"),
        CharacterPrompt(id: "foundation.need", category: .motivation, question: "What do they actually need, even if they would reject the idea?"),
        CharacterPrompt(id: "foundation.success", category: .motivation, question: "How would they know they had finally succeeded?"),
        CharacterPrompt(id: "foundation.price", category: .motivation, question: "What are they unwilling to sacrifice for their biggest goal?"),
        CharacterPrompt(id: "foundation.self-lie", category: .secrets, question: "What lie do they tell themselves?"),
        CharacterPrompt(id: "foundation.hidden-shame", category: .secrets, question: "What are they ashamed of that another person might consider trivial?"),
        CharacterPrompt(id: "foundation.secret-benefit", category: .secrets, question: "What secret currently makes their life easier, not harder?"),
        CharacterPrompt(id: "foundation.childhood", category: .background, question: "What childhood experience still influences their decisions?"),
        CharacterPrompt(id: "foundation.learned-rule", category: .background, question: "What rule about life did they learn young and never seriously question?"),
        CharacterPrompt(id: "foundation.reputation-gap", category: .background, question: "Where does their reputation differ most from the truth?"),
        CharacterPrompt(id: "foundation.regret", category: .background, question: "Which past choice would they make differently if nobody ever knew?"),
        CharacterPrompt(id: "foundation.conflict-style", category: .conflict, question: "When confronted, do they fight, charm, negotiate, freeze, flee or plan revenge?"),
        CharacterPrompt(id: "foundation.breaking-point", category: .conflict, question: "What could push them to do something they normally consider unforgivable?"),
        CharacterPrompt(id: "foundation.apology", category: .conflict, question: "What kind of wrongdoing can they apologise for easily, and what kind makes them defensive?"),
        CharacterPrompt(id: "foundation.losing-control", category: .conflict, question: "What does losing control look like for them?"),
        CharacterPrompt(id: "foundation.home", category: .lifestyle, question: "What does their living space reveal that their public persona does not?"),
        CharacterPrompt(id: "foundation.food", category: .lifestyle, question: "What do they eat when comfort matters more than dignity, health or appearances?"),
        CharacterPrompt(id: "foundation.routine", category: .lifestyle, question: "Which daily routine makes them feel stable, and what happens when it is disrupted?"),
        CharacterPrompt(id: "foundation.money", category: .lifestyle, question: "Are they instinctively a saver, spender, hoarder, giver or gambler with resources?"),
        CharacterPrompt(id: "foundation.friendship", category: .relationships, question: "What makes someone become a real friend rather than merely useful or pleasant company?"),
        CharacterPrompt(id: "foundation.trust", category: .relationships, question: "How does another person earn their trust, and how quickly can they lose it?"),
        CharacterPrompt(id: "foundation.jealousy", category: .relationships, question: "What kind of attention or success in someone else makes them jealous?"),
        CharacterPrompt(id: "foundation.care", category: .relationships, question: "How do they show care when saying it directly feels uncomfortable?"),
        CharacterPrompt(id: "foundation.identity-label", category: .identity, question: "Which label or description of themselves matters most to them?"),
        CharacterPrompt(id: "foundation.identity-misread", category: .identity, question: "What do people routinely assume about them that is wrong?"),
        CharacterPrompt(id: "foundation.name", category: .identity, question: "How do they feel about their own name, nickname or title?"),
        CharacterPrompt(id: "foundation.world-rule", category: .world, question: "Which rule of their society do they treat as natural even though an outsider might question it?"),
        CharacterPrompt(id: "foundation.authority", category: .world, question: "What kind of authority do they instinctively respect, and what kind do they resist?"),
        CharacterPrompt(id: "foundation.belonging", category: .world, question: "Where in their world do they feel they truly belong?"),
        CharacterPrompt(id: "foundation.old-wound", category: .trauma, question: "What old hurt still changes their behaviour even if they would not call it trauma?"),
        CharacterPrompt(id: "foundation.trigger", category: .trauma, question: "What harmless situation can produce a reaction that surprises other people?"),
        CharacterPrompt(id: "foundation.recovery", category: .trauma, question: "What helps them recover after an emotionally difficult experience?"),
        CharacterPrompt(id: "foundation.role-choice", category: .storyRole, question: "What choice best demonstrates the role they play in this story?"),
        CharacterPrompt(id: "foundation.arc-resistance", category: .storyRole, question: "What change does the story need from them that they are most resistant to making?"),
        CharacterPrompt(id: "foundation.arc-proof", category: .storyRole, question: "What event would prove they have genuinely changed rather than merely saying they have?")
    ]

    private static let fantasy: [CharacterPrompt] = [
        CharacterPrompt(id: "fantasy.tavern", category: .lifestyle, question: "At the end of a long day, would they rather drink in a crowded tavern, sit quietly by the fire, or explore beyond the walls? Why?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.adventure", category: .motivation, question: "What would make them leave safety behind and go adventuring?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.magic", category: .world, question: "How do they feel about magic: wonder, suspicion, envy, fear, duty or simple practicality?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.magic-law", category: .world, question: "Which use of magic do they believe should be forbidden, if any?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.creatures", category: .world, question: "Which creature of this world fascinates them, and which do they avoid?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.travel", category: .lifestyle, question: "What do they always carry when travelling between settlements?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.faith", category: .world, question: "What do they believe about gods, spirits, fate or prophecy?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.quest", category: .storyRole, question: "What kind of quest would they refuse even if the reward were enormous?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.monster-mercy", category: .conflict, question: "What supposedly monstrous being could make them hesitate before attacking?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.oath", category: .motivation, question: "What oath, debt or promise could override their personal wishes?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.status", category: .identity, question: "How do rank, bloodline, guild, clan or magical ability affect how they see themselves?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.ruins", category: .world, question: "When they encounter ancient ruins, are they curious, cautious, greedy, reverent or uninterested?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.weapon", category: .appearance, question: "If they carry a weapon or focus, what does its condition say about them?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.camp", category: .lifestyle, question: "Around a travelling camp, which chore do they naturally take responsibility for?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.legend", category: .background, question: "Which local legend did they grow up believing?", genres: [.fantasy]),
        CharacterPrompt(id: "fantasy.power", category: .secrets, question: "If they could gain extraordinary power at a private moral cost, what cost might tempt them?", genres: [.fantasy])
    ]

    private static let scienceFiction: [CharacterPrompt] = [
        CharacterPrompt(id: "scifi.tech", category: .world, question: "Which technology do they trust with their life, and which do they refuse to use?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.ai", category: .world, question: "Do they treat artificial intelligence as a tool, a person, a threat, or something else?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.augmentation", category: .identity, question: "Would they alter their body or mind if augmentation offered a major advantage?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.power", category: .conflict, question: "Which corporation, government or institution has power over their life?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.privacy", category: .secrets, question: "What information about themselves would they never willingly put into a networked system?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.distance", category: .relationships, question: "How do long distances, time delay or virtual presence change their relationships?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.homeworld", category: .identity, question: "What does their planet, habitat or station of origin mean to them?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.synthetic-body", category: .identity, question: "Which part of personhood do they believe depends on a biological body, if any?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.first-contact", category: .world, question: "What would make them trust an unfamiliar intelligent species?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.scarcity", category: .lifestyle, question: "Which resource do they never waste because their environment taught them it was precious?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.memory", category: .trauma, question: "If memory could be edited or replayed, which memory would they protect from interference?", genres: [.scienceFiction]),
        CharacterPrompt(id: "scifi.frontier", category: .motivation, question: "What would persuade them to leave a safe settled world for an unknown frontier?", genres: [.scienceFiction])
    ]

    private static let romance: [CharacterPrompt] = [
        CharacterPrompt(id: "romance.attraction", category: .relationships, question: "What attracts them immediately, and what kind of attraction grows slowly?", genres: [.romance]),
        CharacterPrompt(id: "romance.guard", category: .relationships, question: "What makes them lower their emotional guard?", genres: [.romance]),
        CharacterPrompt(id: "romance.sabotage", category: .conflict, question: "How might they sabotage a relationship they actually want?", genres: [.romance]),
        CharacterPrompt(id: "romance.future", category: .motivation, question: "What does a satisfying long-term partnership look like to them?", genres: [.romance]),
        CharacterPrompt(id: "romance.flirting", category: .personality, question: "How do they flirt when confident, and how does it change when they genuinely care?", genres: [.romance]),
        CharacterPrompt(id: "romance.vulnerability", category: .relationships, question: "What vulnerability do they find harder than physical intimacy?", genres: [.romance]),
        CharacterPrompt(id: "romance.jealousy", category: .conflict, question: "What kind of jealousy do they admit to, and what kind do they disguise?", genres: [.romance]),
        CharacterPrompt(id: "romance.ex", category: .background, question: "What did a previous relationship teach them that may not actually be true?", genres: [.romance]),
        CharacterPrompt(id: "romance.apology", category: .relationships, question: "What does a meaningful apology look like to them?", genres: [.romance]),
        CharacterPrompt(id: "romance.public-private", category: .lifestyle, question: "How different are they as a partner in public versus in private?", genres: [.romance]),
        CharacterPrompt(id: "romance.dealbreaker", category: .relationships, question: "What would end a relationship no matter how strong the attraction?", genres: [.romance]),
        CharacterPrompt(id: "romance.choice", category: .storyRole, question: "What choice would prove that love changed their priorities without erasing who they are?", genres: [.romance])
    ]

    private static let mysteryThriller: [CharacterPrompt] = [
        CharacterPrompt(id: "mystery.secret", category: .secrets, question: "What fact about them would make them look suspicious even if they are innocent?", genres: [.mystery, .thriller]),
        CharacterPrompt(id: "mystery.notice", category: .personality, question: "What detail do they notice that most people overlook?", genres: [.mystery, .thriller]),
        CharacterPrompt(id: "mystery.lie", category: .secrets, question: "What kind of lie are they best at detecting, and what kind fools them?", genres: [.mystery, .thriller]),
        CharacterPrompt(id: "mystery.evidence", category: .conflict, question: "What piece of evidence would they be tempted to hide for personal reasons?", genres: [.mystery, .thriller]),
        CharacterPrompt(id: "mystery.suspect", category: .relationships, question: "Who would they find hardest to suspect even when the evidence points there?", genres: [.mystery, .thriller]),
        CharacterPrompt(id: "mystery.method", category: .personality, question: "Do they solve problems through observation, empathy, logic, persistence, intimidation or intuition?", genres: [.mystery, .thriller]),
        CharacterPrompt(id: "mystery.authority", category: .world, question: "How much do they trust police, courts, experts or other official investigators?", genres: [.mystery, .thriller]),
        CharacterPrompt(id: "mystery.obsession", category: .motivation, question: "What unanswered question could become an unhealthy obsession?", genres: [.mystery, .thriller]),
        CharacterPrompt(id: "thriller.risk", category: .conflict, question: "How much danger will they accept before survival matters more than the mission?", genres: [.thriller]),
        CharacterPrompt(id: "thriller.pursuit", category: .lifestyle, question: "When forced to disappear quickly, what part of their normal life is hardest to abandon?", genres: [.thriller]),
        CharacterPrompt(id: "thriller.leverage", category: .relationships, question: "Who could an enemy use as leverage against them?", genres: [.thriller]),
        CharacterPrompt(id: "thriller.protocol", category: .conflict, question: "Under extreme pressure, do they trust procedure or improvise?", genres: [.thriller]),
        CharacterPrompt(id: "thriller.paranoia", category: .trauma, question: "What would make reasonable caution turn into paranoia for them?", genres: [.thriller]),
        CharacterPrompt(id: "thriller.after", category: .storyRole, question: "If they survive the central threat, what part of ordinary life may no longer fit?", genres: [.thriller])
    ]

    private static let horror: [CharacterPrompt] = [
        CharacterPrompt(id: "horror.fear", category: .trauma, question: "What frightens them before anything supernatural happens?", genres: [.horror]),
        CharacterPrompt(id: "horror.denial", category: .personality, question: "How long would they rationalise impossible events before accepting something is wrong?", genres: [.horror]),
        CharacterPrompt(id: "horror.survival", category: .conflict, question: "Whom would they risk their own life to save?", genres: [.horror]),
        CharacterPrompt(id: "horror.dark", category: .lifestyle, question: "What ordinary nighttime ritual makes them feel safe?", genres: [.horror]),
        CharacterPrompt(id: "horror.taboo", category: .world, question: "Which taboo or warning would they ignore because it sounds irrational?", genres: [.horror]),
        CharacterPrompt(id: "horror.guilt", category: .secrets, question: "What guilt would a hostile force be able to exploit?", genres: [.horror]),
        CharacterPrompt(id: "horror.isolation", category: .relationships, question: "Who would they call first if nobody else believed what they saw?", genres: [.horror]),
        CharacterPrompt(id: "horror.body", category: .appearance, question: "How would they react if their own body stopped feeling completely trustworthy?", genres: [.horror]),
        CharacterPrompt(id: "horror.curiosity", category: .motivation, question: "What could make curiosity stronger than self-preservation?", genres: [.horror]),
        CharacterPrompt(id: "horror.aftermath", category: .trauma, question: "What part of surviving would be hardest for them to explain afterward?", genres: [.horror])
    ]

    private static let historical: [CharacterPrompt] = [
        CharacterPrompt(id: "historical.class", category: .world, question: "What social class were they born into, and what restrictions does it create?", genres: [.historical]),
        CharacterPrompt(id: "historical.custom", category: .world, question: "Which social custom of their time do they quietly resent?", genres: [.historical]),
        CharacterPrompt(id: "historical.faith", category: .world, question: "How does religion or prevailing moral belief shape their daily decisions?", genres: [.historical]),
        CharacterPrompt(id: "historical.work", category: .lifestyle, question: "What skill or labour would people of their time expect them to know?", genres: [.historical]),
        CharacterPrompt(id: "historical.status", category: .identity, question: "Which title, family connection or social marker changes how others treat them?", genres: [.historical]),
        CharacterPrompt(id: "historical.reputation", category: .relationships, question: "Whose good opinion matters because reputation has practical consequences?", genres: [.historical]),
        CharacterPrompt(id: "historical.travel", category: .lifestyle, question: "How far from home have they travelled, and what did that distance mean in their time?", genres: [.historical]),
        CharacterPrompt(id: "historical.rule", category: .conflict, question: "Which law or convention would they risk breaking?", genres: [.historical]),
        CharacterPrompt(id: "historical.news", category: .world, question: "How do they learn what is happening beyond their immediate community?", genres: [.historical]),
        CharacterPrompt(id: "historical.future", category: .motivation, question: "What future do they imagine is realistically available to someone in their position?", genres: [.historical])
    ]

    private static let contemporary: [CharacterPrompt] = [
        CharacterPrompt(id: "contemporary.phone", category: .lifestyle, question: "What would someone learn about them from five minutes with their phone?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.weekend", category: .lifestyle, question: "What does an ordinary free Saturday look like for them?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.pressure", category: .conflict, question: "Which ordinary modern pressure gets under their skin most?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.social", category: .identity, question: "How different is the version of themselves they present online?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.work", category: .motivation, question: "Is work primarily identity, income, duty, ambition or something to escape?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.money", category: .lifestyle, question: "Which expense do they consider essential that someone else might call wasteful?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.family-chat", category: .relationships, question: "What role do they play in the family or friend group chat?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.news", category: .world, question: "Which public issue can reliably start an argument with them?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.neighbour", category: .relationships, question: "How well do they know the people living physically closest to them?", genres: [.contemporary]),
        CharacterPrompt(id: "contemporary.burnout", category: .trauma, question: "What warning sign tells them they are approaching burnout?", genres: [.contemporary])
    ]

    private static let adventureCrime: [CharacterPrompt] = [
        CharacterPrompt(id: "adventure.danger", category: .motivation, question: "Why do they keep going when turning back would be safer?", genres: [.adventure]),
        CharacterPrompt(id: "adventure.team", category: .relationships, question: "What role do they naturally take in a group under pressure?", genres: [.adventure]),
        CharacterPrompt(id: "adventure.failure", category: .conflict, question: "What kind of failure frightens them more than physical danger?", genres: [.adventure]),
        CharacterPrompt(id: "adventure.supplies", category: .lifestyle, question: "What do they pack too much of, and what do they always forget?", genres: [.adventure]),
        CharacterPrompt(id: "adventure.map", category: .world, question: "Do they trust maps, local knowledge, instinct or technology when those sources disagree?", genres: [.adventure]),
        CharacterPrompt(id: "adventure.glory", category: .motivation, question: "How much does being remembered matter to them?", genres: [.adventure]),
        CharacterPrompt(id: "crime.line", category: .conflict, question: "What crime would they never commit, even if they already break other laws?", genres: [.crime]),
        CharacterPrompt(id: "crime.loyalty", category: .relationships, question: "Would they betray an accomplice to save themselves?", genres: [.crime]),
        CharacterPrompt(id: "crime.money", category: .motivation, question: "What amount of money would genuinely change their life, and what would they do with it?", genres: [.crime]),
        CharacterPrompt(id: "crime.code", category: .world, question: "Which unwritten rule of their criminal world do they take seriously?", genres: [.crime]),
        CharacterPrompt(id: "crime.cover", category: .identity, question: "What ordinary part of their life makes the best cover for what they really do?", genres: [.crime]),
        CharacterPrompt(id: "crime.fear", category: .trauma, question: "Do they fear prison, betrayal, violence, exposure or losing control most?", genres: [.crime])
    ]

    private static let youngAdult: [CharacterPrompt] = [
        CharacterPrompt(id: "ya.identity", category: .identity, question: "Which part of their identity are they still trying to define?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.parent", category: .relationships, question: "Which adult do they most want approval from, and which do they resist?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.future", category: .motivation, question: "What future are they afraid will be chosen for them?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.friend-group", category: .relationships, question: "What role do they play in their friend group, and do they actually like that role?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.first-freedom", category: .motivation, question: "What freedom do they want before they are ready for its consequences?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.shame", category: .secrets, question: "What ordinary thing about themselves feels humiliating because they believe everybody notices it?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.adult-mask", category: .identity, question: "When do they pretend to be more mature or certain than they feel?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.home", category: .background, question: "What part of home are they desperate to leave, and what part would they miss?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.risk", category: .conflict, question: "Which risk would they take mainly because someone told them they could not?", genres: [.youngAdult]),
        CharacterPrompt(id: "ya.change", category: .storyRole, question: "What belief about themselves needs to become more complicated by the end of the story?", genres: [.youngAdult])
    ]
}

private extension String {
    func containsAny(_ terms: [String]) -> Bool {
        terms.contains { contains($0) }
    }
}
