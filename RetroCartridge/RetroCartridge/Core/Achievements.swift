// Achievements.swift
// RetroCartridge
//
// Five achievements per cartridge: score anything, reach its level goal,
// reach its score goal, finish a daily round and finish a round in every
// mode. They're checked every frame against the running game and stored by
// id in `ProgressStore`, which also keeps a hidden record of which modes
// each cartridge has finished.

import Foundation

// MARK: - Achievement

struct Achievement: Identifiable, Hashable, Sendable {

    /// What the player has to do.
    enum Goal: Hashable, Sendable {
        case score(Int)
        case level(Int)
        case finishDaily
        case finishEveryMode
    }

    let game: GameType
    let goal: Goal
    let title: String
    let detail: String

    /// Stable id, used as the persistence key. Never change a shipped one.
    var id: String {
        switch goal {
        case .score(1): return "\(game.rawValue).first-points"
        case .score: return "\(game.rawValue).high-scorer"
        case .level: return "\(game.rawValue).level-goal"
        case .finishDaily: return "\(game.rawValue).daily"
        case .finishEveryMode: return "\(game.rawValue).explorer"
        }
    }

    /// Every achievement of a cartridge, in the order they're shown.
    static func all(for game: GameType) -> [Achievement] {
        let info = game.info
        return [
            Achievement(game: game, goal: .score(1), title: "OFF THE MARK", detail: "Score your first points"),
            Achievement(game: game, goal: .level(info.levelGoal), title: "LEVEL \(info.levelGoal)", detail: "Reach level \(info.levelGoal)"),
            Achievement(game: game, goal: .score(info.scoreGoal), title: "HIGH SCORER", detail: "Score \(info.scoreGoal) in one round"),
            Achievement(game: game, goal: .finishDaily, title: "DAILY PLAYER", detail: "Finish a daily round"),
            Achievement(game: game, goal: .finishEveryMode, title: "EXPLORER", detail: "Finish a round in every mode")
        ]
    }
}

// MARK: - Tracker

enum AchievementTracker {

    /// The hidden record that a cartridge has finished a round in a mode.
    static func finishedModeID(game: GameType, mode: GameMode) -> String {
        "\(game.rawValue).finished.\(mode.id)"
    }

    /// Checks the running game and records what it has just earned.
    /// - Returns: The achievements earned by this call, to announce.
    @discardableResult
    static func check(_ game: any PixelGameProtocol, progress: ProgressStore) -> [Achievement] {
        let isRoundOver: Bool
        if case .gameOver = game.gameState { isRoundOver = true } else { isRoundOver = false }

        if isRoundOver {
            progress.earn(finishedModeID(game: game.gameType, mode: game.mode))
        }

        var earned: [Achievement] = []
        for achievement in Achievement.all(for: game.gameType) where !progress.hasEarned(achievement.id) {
            let isMet: Bool
            switch achievement.goal {
            case .score(let target):
                isMet = game.score >= target
            case .level(let target):
                isMet = game.level >= target
            case .finishDaily:
                isMet = isRoundOver && game.mode.isDaily
            case .finishEveryMode:
                isMet = game.gameType.modes.allSatisfy {
                    progress.hasEarned(finishedModeID(game: game.gameType, mode: $0))
                }
            }
            if isMet, progress.earn(achievement.id) {
                earned.append(achievement)
            }
        }
        return earned
    }

    /// How many of a cartridge's achievements are earned, out of how many.
    static func tally(for game: GameType, progress: ProgressStore) -> (earned: Int, total: Int) {
        let all = Achievement.all(for: game)
        return (all.filter { progress.hasEarned($0.id) }.count, all.count)
    }
}
