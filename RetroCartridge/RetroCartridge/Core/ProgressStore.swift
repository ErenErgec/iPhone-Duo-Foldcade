// ProgressStore.swift
// RetroCartridge
//
// The player's persistent progress: high scores per cartridge and mode, and
// the achievements earned. Values are held in stored properties, so every
// view showing a score refreshes as soon as a new record is set.

import Foundation
import Observation

@Observable
final class ProgressStore {

    // MARK: - Storage

    private let defaults: UserDefaults

    /// High scores by persistence key (`highScoreKey(for:mode:)`).
    private var highScores: [String: Int]

    /// Identifiers of the achievements earned so far.
    private(set) var earnedAchievements: Set<String>

    private static let achievementsKey = "earnedAchievements"

    /// Loads the saved progress of every cartridge and mode.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        var scores: [String: Int] = [:]
        for game in GameType.allCases {
            for mode in game.modes {
                let key = Self.highScoreKey(for: game, mode: mode)
                scores[key] = defaults.integer(forKey: key)
            }
        }
        highScores = scores
        earnedAchievements = Set(defaults.stringArray(forKey: Self.achievementsKey) ?? [])
    }

    // MARK: - High Scores

    /// The persistence key of a high score. The standard mode keeps the key
    /// used before modes existed, so earlier scores carry over.
    static func highScoreKey(for game: GameType, mode: GameMode) -> String {
        mode.id == GameMode.standard.id
            ? "highScore_\(game.rawValue)"
            : "highScore_\(game.rawValue)_\(mode.id)"
    }

    /// The best score for a cartridge in a mode, 0 if never played.
    func highScore(for game: GameType, mode: GameMode = .standard) -> Int {
        highScores[Self.highScoreKey(for: game, mode: mode)] ?? 0
    }

    /// Saves `score` if it beats the current high score.
    /// - Returns: Whether it was a new high score.
    @discardableResult
    func recordScore(_ score: Int, for game: GameType, mode: GameMode = .standard) -> Bool {
        let key = Self.highScoreKey(for: game, mode: mode)
        guard score > (highScores[key] ?? 0) else { return false }
        highScores[key] = score
        defaults.set(score, forKey: key)
        return true
    }

    // MARK: - Achievements

    /// Whether the achievement with this identifier has been earned.
    func hasEarned(_ achievementID: String) -> Bool {
        earnedAchievements.contains(achievementID)
    }

    /// Marks an achievement as earned.
    /// - Returns: Whether it was newly earned.
    @discardableResult
    func earn(_ achievementID: String) -> Bool {
        guard !earnedAchievements.contains(achievementID) else { return false }
        earnedAchievements.insert(achievementID)
        defaults.set(earnedAchievements.sorted(), forKey: Self.achievementsKey)
        return true
    }
}
