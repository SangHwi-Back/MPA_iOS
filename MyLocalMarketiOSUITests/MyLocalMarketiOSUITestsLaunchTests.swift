//
//  MyLocalMarketiOSUITestsLaunchTests.swift
//  MyLocalMarketiOSUITests
//
//  Created by 백상휘 on 5/27/25.
//

import XCTest

final class MyLocalMarketiOSUITestsLaunchTests: XCTestCase {
    // swiftlint:disable:next static_over_final_class
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
