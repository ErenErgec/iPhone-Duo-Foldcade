// RetroCartridgeTests.swift
// RetroCartridgeTests
//
// Unit tests for app state, display detection and game metadata.

import XCTest
@testable import RetroCartridge

final class RetroCartridgeTests: XCTestCase {
    
    func testAppStatInitialValues() {
        let appState = AppState()
        XCTAssertEqual(appState.selectedGameType, .brickBreaker)
        XCTAssertNil(appState.activeGame)
        XCTAssertFalse(appState.isGameActive)
    }
    
    func testPostureManagerDefaults() {
        let posture = PostureManager()
        XCTAssertEqual(posture.currentPosture, .closed)
        XCTAssertFalse(posture.isCompactWidth)
    }
    
    func testPostureManagerDisplayDetection() {
        let posture = PostureManager()
        
        // iPhone Duo outer display, in either orientation
        posture.updateDisplay(fullScreenSize: CGSize(width: 678, height: 466))
        XCTAssertTrue(posture.isCompactWidth)
        XCTAssertEqual(posture.currentPosture, .closed)
        posture.updateDisplay(fullScreenSize: CGSize(width: 466, height: 678))
        XCTAssertTrue(posture.isCompactWidth)
        
        // iPhone Duo inner display
        posture.updateDisplay(fullScreenSize: CGSize(width: 669, height: 871))
        XCTAssertFalse(posture.isCompactWidth)
        XCTAssertEqual(posture.currentPosture, .fullyOpen)
        posture.updateDisplay(fullScreenSize: CGSize(width: 871, height: 669))
        XCTAssertFalse(posture.isCompactWidth)
    }
    
    func testGameTypeMetadata() {
        for gameType in GameType.allCases {
            XCTAssertFalse(gameType.subtitle.isEmpty)
            XCTAssertFalse(gameType.cartridgeColorHex.isEmpty)
        }
    }
    
    func testSkinThemes() {
        for skin in ConsoleSkinType.allCases {
            let theme = SkinManager.theme(for: skin)
            // Verify theme returns valid values (non-crash)
            _ = theme.bodyColor
            _ = theme.buttonColor
            _ = theme.accentColor
        }
    }

    // MARK: - Cartridges

    func testEveryCartridgeOffersTheStandardModeFirst() {
        for gameType in GameType.allCases {
            XCTAssertEqual(gameType.modes.first, GameMode.standard, gameType.rawValue)
            XCTAssertFalse(gameType.genre.isEmpty)
            XCTAssertFalse(gameType.symbolName.isEmpty)
        }
    }

    func testEngineCreatesGamesInTheirNativePalette() {
        for gameType in GameType.allCases {
            let game = PixelGameEngine.createGame(type: gameType)
            XCTAssertEqual(game.gameType, gameType)
            XCTAssertEqual(game.mode, .standard)
            XCTAssertEqual(game.palette, GamePalette.native(for: gameType))
            XCTAssertEqual(game.gameState, .menu)
        }
    }

    // MARK: - Palette

    func testSpectrumColorWrapsAround() {
        let palette = GamePalette.fallingBlocks
        let count = palette.spectrum.count
        XCTAssertEqual(palette.spectrumColor(0), palette.spectrum[0])
        XCTAssertEqual(palette.spectrumColor(count), palette.spectrum[0])
        XCTAssertEqual(palette.spectrumColor(count + 2), palette.spectrum[2])
        XCTAssertEqual(palette.spectrumColor(-1), palette.spectrum[count - 1])
    }

    func testEmptySpectrumFallsBackToThePlayerColor() {
        var palette = GamePalette.snake
        palette.spectrum = []
        XCTAssertEqual(palette.spectrumColor(3), palette.player)
    }

    // MARK: - Progress

    private func makeDefaults() -> UserDefaults {
        let suiteName = "RetroCartridgeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suiteName) }
        return defaults
    }

    func testStandardModeKeepsTheOriginalHighScoreKey() {
        XCTAssertEqual(ProgressStore.highScoreKey(for: .snake, mode: .standard), "highScore_Snake")
        let sprint = GameMode(id: "sprint", title: "Sprint", summary: "40 lines.")
        XCTAssertEqual(ProgressStore.highScoreKey(for: .fallingBlocks, mode: sprint), "highScore_Falling Blocks_sprint")
    }

    func testHighScoresSavedBeforeModesCarryOver() {
        let defaults = makeDefaults()
        defaults.set(420, forKey: "highScore_Snake")
        let progress = ProgressStore(defaults: defaults)
        XCTAssertEqual(progress.highScore(for: .snake), 420)
        XCTAssertEqual(progress.highScore(for: .retroRacer), 0)
    }

    func testRecordScoreKeepsOnlyTheBest() {
        let defaults = makeDefaults()
        let progress = ProgressStore(defaults: defaults)
        XCTAssertTrue(progress.recordScore(300, for: .brickBreaker))
        XCTAssertFalse(progress.recordScore(200, for: .brickBreaker))
        XCTAssertFalse(progress.recordScore(300, for: .brickBreaker))
        XCTAssertEqual(progress.highScore(for: .brickBreaker), 300)
        XCTAssertEqual(ProgressStore(defaults: defaults).highScore(for: .brickBreaker), 300)
    }

    func testModesKeepSeparateHighScores() {
        let progress = ProgressStore(defaults: makeDefaults())
        let sprint = GameMode(id: "sprint", title: "Sprint", summary: "40 lines.")
        progress.recordScore(500, for: .fallingBlocks, mode: sprint)
        XCTAssertEqual(progress.highScore(for: .fallingBlocks, mode: sprint), 500)
        XCTAssertEqual(progress.highScore(for: .fallingBlocks), 0)
    }

    func testAchievementsPersist() {
        let defaults = makeDefaults()
        let progress = ProgressStore(defaults: defaults)
        XCTAssertTrue(progress.earn("snake.first-apple"))
        XCTAssertFalse(progress.earn("snake.first-apple"))
        XCTAssertTrue(ProgressStore(defaults: defaults).hasEarned("snake.first-apple"))
        XCTAssertFalse(progress.hasEarned("racer.first-mile"))
    }

    func testAppStateRecordsScoresInItsProgressStore() {
        let appState = AppState(progress: ProgressStore(defaults: makeDefaults()))
        appState.updateHighScore(90, for: .snake)
        XCTAssertEqual(appState.highScore(for: .snake), 90)
        XCTAssertEqual(appState.progress.highScore(for: .snake), 90)
    }

    // MARK: - Library grid

    func testLibraryGridBalancesRows() {
        // Room for three: 2 × 2 rather than 3 + 1
        let metrics = LibraryGridMetrics(itemCount: 4, availableWidth: 600, hasFold: false)
        XCTAssertEqual(metrics.columns, 2)
    }

    func testLibraryGridUsesOneRowWhenEverythingFits() {
        let metrics = LibraryGridMetrics(itemCount: 4, availableWidth: 800, hasFold: true)
        XCTAssertEqual(metrics.columns, 4)
        XCTAssertLessThanOrEqual(metrics.itemWidth, LibraryGridMetrics.maxItemWidth)
    }

    func testLibraryGridPrefersEvenColumnsOnAFoldingDisplay() {
        // Five cartridges with room for four: 3 columns flat-out, 4 with a fold
        XCTAssertEqual(LibraryGridMetrics(itemCount: 5, availableWidth: 760, hasFold: false).columns, 3)
        XCTAssertEqual(LibraryGridMetrics(itemCount: 5, availableWidth: 760, hasFold: true).columns, 4)
        // Three cartridges with room for exactly three: drop to two
        XCTAssertEqual(LibraryGridMetrics(itemCount: 3, availableWidth: 520, hasFold: true).columns, 2)
    }

    func testLibraryGridCartridgesFitTheWidth() {
        for width in stride(from: CGFloat(200), through: 1000, by: 50) {
            for hasFold in [false, true] {
                let metrics = LibraryGridMetrics(itemCount: 6, availableWidth: width, hasFold: hasFold)
                let used = metrics.itemWidth * CGFloat(metrics.columns)
                    + LibraryGridMetrics.spacing * CGFloat(metrics.columns - 1)
                XCTAssertLessThanOrEqual(used, width + 0.001, "width \(width), fold \(hasFold)")
                if hasFold && metrics.columns > 1 {
                    XCTAssertEqual(metrics.columns % 2, 0, "width \(width)")
                }
            }
        }
    }

    // MARK: - Cartridge art

    func testEveryCartridgeLabelIsASixteenPixelSquare() {
        for gameType in GameType.allCases {
            let rows = PixelArt.label(for: gameType).rows
            XCTAssertEqual(rows.count, 16, gameType.rawValue)
            for row in rows {
                XCTAssertEqual(row.count, 16, "\(gameType.rawValue): \(row)")
            }
        }
    }

    func testCartridgeLabelsOnlyUseKnownPixels() {
        for gameType in GameType.allCases {
            let palette = GamePalette.native(for: gameType)
            for character in PixelArt.label(for: gameType).rows.joined() where character != "." {
                XCTAssertNotNil(PixelArt.color(for: character, in: palette), "\(gameType.rawValue): \(character)")
            }
        }
    }

    // MARK: - Screen

    func testScreenSettingsRoundTrip() throws {
        let settings = ScreenSettings(mode: .trinitron, curvature: 0.2, scanlines: 0.9, bleed: 0.4)
        let data = try JSONEncoder().encode(settings)
        XCTAssertEqual(try JSONDecoder().decode(ScreenSettings.self, from: data), settings)
        XCTAssertFalse(settings.hasStandardTuning)
        XCTAssertTrue(ScreenSettings(mode: .arcade).hasStandardTuning)
    }

    func testOnlyColorCRTIsFree() {
        XCTAssertNil(ScreenMode.crt.requiredProductID)
        for mode in ScreenMode.allCases where mode != .crt {
            XCTAssertEqual(mode.requiredProductID, ProductIdentifiers.lifetimePro)
        }
    }

    // MARK: - Attract mode

    func testAttractPilotPlaysEveryGame() {
        for gameType in GameType.allCases {
            let pilot = AttractPilot(type: gameType)
            var bestScore = 0
            // Thirty seconds at 60 FPS
            for _ in 0..<1_800 {
                pilot.step(deltaTime: 1.0 / 60)
                bestScore = max(bestScore, pilot.game.score)
                XCTAssertTrue(pilot.game.pendingSounds.isEmpty, "attract mode is silent")
            }
            XCTAssertGreaterThan(bestScore, 0, gameType.rawValue)
            XCTAssertNotEqual(pilot.game.gameState, .menu, gameType.rawValue)
        }
    }

    // MARK: - Pause menu and eject

    private func makePausedAppState() -> AppState {
        let appState = AppState(progress: ProgressStore(defaults: makeDefaults()))
        appState.startGame(type: .snake)
        appState.activeGame?.handleInput(action: .buttonAPressed)
        appState.activeGame?.pause()
        return appState
    }

    func testPauseMenuIsActiveOnlyWhilePaused() {
        let appState = makePausedAppState()
        XCTAssertTrue(appState.isPauseMenuActive)
        appState.activeGame?.resume()
        XCTAssertFalse(appState.isPauseMenuActive)
    }

    func testPauseMenuSelectionWraps() {
        let appState = makePausedAppState()
        XCTAssertEqual(appState.pauseMenuSelection, .resume)
        PauseMenu.handle(.dpadUpPressed, appState: appState, screenModes: [.crt], currentScreen: .crt)
        XCTAssertEqual(appState.pauseMenuSelection, .eject)
        PauseMenu.handle(.dpadDownPressed, appState: appState, screenModes: [.crt], currentScreen: .crt)
        XCTAssertEqual(appState.pauseMenuSelection, .resume)
    }

    func testPauseMenuResumesWithB() {
        let appState = makePausedAppState()
        PauseMenu.handle(.buttonBPressed, appState: appState, screenModes: [.crt], currentScreen: .crt)
        XCTAssertEqual(appState.activeGame?.gameState, .playing)
    }

    func testPauseMenuCyclesOnlyUnlockedScreens() {
        let appState = makePausedAppState()
        // AppState persists screen settings in the app's own defaults, so
        // put back whatever was set on this simulator
        let original = appState.screenSettings
        defer { appState.screenSettings = original }
        appState.screenSettings = .standard
        appState.pauseMenuSelection = .screen
        XCTAssertEqual(
            PauseMenu.handle(.dpadRightPressed, appState: appState, screenModes: [.crt], currentScreen: .crt),
            .ignored
        )
        PauseMenu.handle(.dpadLeftPressed, appState: appState, screenModes: [.crt, .lcd, .arcade], currentScreen: .crt)
        XCTAssertEqual(appState.screenSettings.mode, .arcade)
    }

    func testEjectingKeepsTheGameUntilThePowerOffEnds() {
        let appState = makePausedAppState()
        appState.pauseMenuSelection = .eject
        PauseMenu.handle(.buttonAPressed, appState: appState, screenModes: [.crt], currentScreen: .crt)
        XCTAssertTrue(appState.isEjecting)
        XCTAssertNotNil(appState.activeGame)
        XCTAssertFalse(appState.isPauseMenuActive)
        appState.endGame()
        XCTAssertFalse(appState.isEjecting)
        XCTAssertNil(appState.activeGame)
    }

    // MARK: - Variety infrastructure

    func testModesAreTheSameRuleSetWhenTheirIdsMatch() {
        let marathon = GameMode(id: "standard", title: "Marathon", summary: "Endless.")
        XCTAssertEqual(marathon, .standard)
        XCTAssertEqual(Set([marathon, .standard]).count, 1)
        XCTAssertNotEqual(GameMode.daily, .standard)
    }

    func testDailyRoundsAreDealtTheSameWay() {
        func pieces(_ game: FallingBlocksGame) -> [Int] {
            (0..<12).map { _ in game.randomPiece().colorIndex }
        }
        let first = PixelGameEngine.createGame(type: .fallingBlocks, mode: .daily) as! FallingBlocksGame
        let second = PixelGameEngine.createGame(type: .fallingBlocks, mode: .daily) as! FallingBlocksGame
        XCTAssertEqual(pieces(first), pieces(second))
    }

    func testDailySeedDependsOnGameAndDay() {
        let day = "2026-09-29"
        XCTAssertEqual(DailySeed.seed(for: .snake, day: day), DailySeed.seed(for: .snake, day: day))
        XCTAssertNotEqual(DailySeed.seed(for: .snake, day: day), DailySeed.seed(for: .retroRacer, day: day))
        XCTAssertNotEqual(DailySeed.seed(for: .snake, day: day), DailySeed.seed(for: .snake, day: "2026-09-30"))
        XCTAssertEqual(DailySeed.dayKey(for: Date(timeIntervalSince1970: 0)), "1970-01-01")
    }

    func testDailyHighScoresStartOverEachDay() {
        let defaults = makeDefaults()
        var day = "2026-09-29"
        let progress = ProgressStore(defaults: defaults, today: { day })
        XCTAssertTrue(progress.recordScore(500, for: .snake, mode: .daily))
        XCTAssertEqual(progress.highScore(for: .snake, mode: .daily), 500)

        day = "2026-09-30"
        XCTAssertEqual(progress.highScore(for: .snake, mode: .daily), 0)
        XCTAssertTrue(progress.recordScore(100, for: .snake, mode: .daily))
        XCTAssertEqual(ProgressStore(defaults: defaults, today: { day }).highScore(for: .snake, mode: .daily), 100)
    }

    func testModeCyclesOnlyOnTheTitleAndGameOverScreens() {
        let appState = AppState(progress: ProgressStore(defaults: makeDefaults()))
        appState.startGame(type: .snake)
        XCTAssertTrue(appState.cycleMode(by: 1))
        XCTAssertEqual(appState.activeGame?.mode, GameType.snake.modes[1])
        XCTAssertEqual(appState.activeGame?.gameState, .menu)

        appState.activeGame?.handleInput(action: .buttonAPressed)
        XCTAssertFalse(appState.cycleMode(by: 1))
    }

    func testPaletteChoiceRecolorsTheRunningGame() {
        let appState = AppState(progress: ProgressStore(defaults: makeDefaults()))
        let original = appState.paletteChoice
        defer { appState.paletteChoice = original }

        appState.paletteChoice = .original
        appState.startGame(type: .snake)
        XCTAssertEqual(appState.activeGame?.palette, GamePalette.snake)
        appState.paletteChoice = .dmgGreen
        XCTAssertEqual(appState.activeGame?.palette, GamePalette.dmgGreen)
    }

    func testPauseMenuCyclesPalettes() {
        let appState = makePausedAppState()
        let original = appState.paletteChoice
        defer { appState.paletteChoice = original }

        appState.paletteChoice = .original
        appState.pauseMenuSelection = .palette
        PauseMenu.handle(.dpadRightPressed, appState: appState, screenModes: [.crt], currentScreen: .crt)
        XCTAssertEqual(appState.paletteChoice, PaletteChoice.allCases[1])
    }

    // MARK: - Brick Breaker

    func testEveryBrickBreakerWallCanBeCleared() {
        let game = BrickBreakerGame()
        for index in BrickBreakerGame.levels.indices {
            game.level = index + 1
            game.setupLevel()
            XCTAssertTrue(game.bricks.contains { $0.kind != .steel }, "level \(index + 1)")
            XCTAssertTrue(game.bricks.allSatisfy { $0.x < game.cols && $0.y < game.rows }, "level \(index + 1)")
        }
    }

    func testBallWaitsOnThePaddleUntilLaunched() {
        let game = BrickBreakerGame()
        game.handleInput(action: .buttonAPressed)
        XCTAssertEqual(game.gameState, .playing)
        XCTAssertNotNil(game.balls.first?.stuckOffset)

        game.handleInput(action: .buttonAPressed)
        XCTAssertNil(game.balls.first?.stuckOffset)
        XCTAssertLessThan(game.balls.first?.vy ?? 0, 0)
    }

    func testBallLaunchesByItselfAfterAWhile() {
        let game = BrickBreakerGame()
        game.handleInput(action: .buttonAPressed)
        for _ in 0..<180 {
            game.update(deltaTime: 1.0 / 60)
        }
        XCTAssertNil(game.balls.first?.stuckOffset)
    }

    func testToughBricksTakeTwoHits() {
        let game = BrickBreakerGame()
        game.level = 4 // Armored core
        game.setupLevel()
        let tough = game.bricks.firstIndex { $0.kind == .tough }!
        game.hitBrick(tough)
        XCTAssertFalse(game.bricks[tough].isDestroyed)
        game.hitBrick(tough)
        XCTAssertTrue(game.bricks[tough].isDestroyed)

        let steel = game.bricks.firstIndex { $0.kind == .steel }
        XCTAssertNil(steel, "Armored core has no steel")
    }

    func testSteelBricksNeverBreak() {
        let game = BrickBreakerGame()
        game.level = 5 // Steel gates
        game.setupLevel()
        let steel = game.bricks.firstIndex { $0.kind == .steel }!
        for _ in 0..<5 {
            game.hitBrick(steel)
        }
        XCTAssertFalse(game.bricks[steel].isDestroyed)
    }

    // MARK: - Snake

    func testWrapModeCarriesTheSnakeAcrossTheEdge() {
        let game = PixelGameEngine.createGame(type: .snake, mode: .snakeWrap) as! SnakeGame
        game.handleInput(action: .buttonAPressed)
        game.snake = [SnakeGame.SnakeSegment(x: 19, y: 3), SnakeGame.SnakeSegment(x: 18, y: 3)]
        game.food = SnakeGame.SnakeSegment(x: 5, y: 15)
        game.moveSnake()
        XCTAssertEqual(game.gameState, .playing)
        XCTAssertEqual(game.snake.first, SnakeGame.SnakeSegment(x: 0, y: 3))
    }

    func testClassicModeWallsAreDeadly() {
        let game = PixelGameEngine.createGame(type: .snake, mode: .snakeClassic) as! SnakeGame
        game.handleInput(action: .buttonAPressed)
        game.snake = [SnakeGame.SnakeSegment(x: 19, y: 3), SnakeGame.SnakeSegment(x: 18, y: 3)]
        game.moveSnake()
        XCTAssertNotEqual(game.gameState, .playing)
    }

    func testMazesLeaveTheStartClear() {
        let start = (8...19).map { SnakeGame.SnakeSegment(x: $0, y: 10) }
        for layout in 0..<4 {
            let walls = SnakeGame.maze(layout)
            XCTAssertFalse(walls.isEmpty)
            XCTAssertTrue(walls.isDisjoint(with: start), "layout \(layout)")
        }
    }

    // MARK: - Falling Blocks

    func testSprintEndsAtFortyLines() {
        let game = PixelGameEngine.createGame(type: .fallingBlocks, mode: .blocksSprint) as! FallingBlocksGame
        game.handleInput(action: .buttonAPressed)
        game.linesClearedTotal = 39
        game.grid[game.rows - 1] = Array(repeating: 0, count: game.cols)
        game.clearLines()
        XCTAssertNotEqual(game.gameState, .playing)
        XCTAssertGreaterThan(game.score, 0)
    }

    func testUltraEndsAfterTwoMinutes() {
        let game = PixelGameEngine.createGame(type: .fallingBlocks, mode: .blocksUltra) as! FallingBlocksGame
        game.handleInput(action: .buttonAPressed)
        game.elapsed = game.ultraDuration - 0.01
        game.update(deltaTime: 0.02)
        XCTAssertNotEqual(game.gameState, .playing)
    }

    func testThreePiecesAreAlwaysPreviewed() {
        let game = FallingBlocksGame()
        XCTAssertGreaterThanOrEqual(game.upcoming.count, game.previewCount)
        game.handleInput(action: .buttonAPressed)
        game.handleInput(action: .dpadUpPressed)
        XCTAssertGreaterThanOrEqual(game.upcoming.count, game.previewCount)
    }

    // MARK: - Retro Racer

    func testCoinsScore() {
        let game = RetroRacerGame()
        game.handleInput(action: .buttonAPressed)
        game.coins = [RetroRacerGame.Coin(lane: game.targetLane, y: 0.82)]
        game.update(deltaTime: 1.0 / 60)
        XCTAssertTrue(game.coins.isEmpty)
        XCTAssertGreaterThanOrEqual(game.score, 10)
    }
}
