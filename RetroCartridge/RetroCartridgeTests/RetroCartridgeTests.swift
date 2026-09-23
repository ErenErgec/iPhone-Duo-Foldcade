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
}
