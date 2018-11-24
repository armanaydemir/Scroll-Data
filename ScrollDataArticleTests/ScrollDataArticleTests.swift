//
//  ScrollDataArticleTests.swift
//  ScrollDataArticleTests
//
//  Created by Aydemir on 11/21/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import XCTest

class ScrollDataArticleTests: XCTestCase {
    let app = XCUIApplication()
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sleep(10)
    }

    
    func testReadArticle(){
        //------------
        self.app.tables["startingTable"].waitForExistence(timeout: 5)
        XCTAssert(self.app.tables["startingTable"].cells.count > 1)
        //waits for table view to load and makes sure it is not empty
        
        //-----------
        self.app.tables["startingTable"].cells.element(boundBy: 0).tap()
        self.app.tables["articleTable"].waitForExistence(timeout: 5)
        //click on an article and waits for it to load, need to check for specific 'server not connected' msg
       
        //https://stackoverflow.com/questions/40923929/scroll-the-cells-using-ui-testing
        let table = self.app.tables["articleTable"]
        let tableCenter = table.coordinate(withNormalizedOffset:CGVector(dx: 0.5, dy: 0.5))
        
        // Scroll from tableBottom to new coordinate
        let scrollVector = table.coordinate(withNormalizedOffset:CGVector(dx: 0.5, dy: 0.1)) // Use whatever vector you like
        while(!table.cells["submitCell"].isHittable){
            tableCenter.press(forDuration: 0.0, thenDragTo: scrollVector)
        }
        self.app.cells["submitCell"].tap()
        
    }

}
