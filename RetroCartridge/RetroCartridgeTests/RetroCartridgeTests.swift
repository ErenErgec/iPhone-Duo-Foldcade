// RetroCartridgeTests.swift
// RetroCartridgeTests
//
// Placeholder test file for the RetroCartridge test target.

import XCTest
@testable import RetroCartridge

final class RetroCartridgeTests: XCTestCase {
    
    func testAppStatInitialValues() {
        let appState = AppState()
        XCTAssertEqual(appState.selectedGameType, .brickBreaker)
        XCTAssertNil(appState.activeGame)
        XCTAssertFalse(appState.isGameActive)
        XCTAssertFalse(appState.isInsertingCartridge)
        XCTAssertFalse(appState.hasPoweredOn)
    }
    
    func testPostureManagerDefaults() {
        let posture = PostureManager()
        XCTAssertEqual(posture.currentPosture, .fullyOpen)
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
}
