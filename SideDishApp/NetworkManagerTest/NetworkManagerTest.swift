//
//  NetworkManagerTest.swift
//  NetworkManagerTest
//
//  Created by 박진섭 on 2022/05/11.
//

import XCTest

class NetworkManagerTest: XCTestCase {
    
    var sut: NetworkManagable!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = NetworkManager(session: .shared)
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testNetworkManager() throws {
        // MockData - Main
        guard let path = Bundle.main.path(forResource: "MainMockData", ofType: "json") else { return }
        guard let jsonString = try? String(contentsOfFile: path) else { return }
        guard let mainDishMockdata = jsonString.data(using: .utf8) else { return }
        
        // MockData - detail
        guard let path = Bundle.main.path(forResource: "DetailMockData", ofType: "json") else { return }
        guard let jsonString = try? String(contentsOfFile: path) else { return }
        guard let dishDetailMockdata = jsonString.data(using: .utf8) else { return }
        
        // Decoded MockData with specific type
        guard let expectedDecodedMain = try? JSONDecoder().decode(SideDishInfo.self, from: mainDishMockdata) else { return }
        guard let expectedDecodedDetail = try? JSONDecoder().decode(DetailDishInfo.self, from: dishDetailMockdata) else { return }
        
        // mockEndpoint
        let mainDishMockEndPoint = EndPointCase.get(category: .main).endpoint
        let detailMockEndPoint = EndPointCase.getDetail(hash: "H1AA9").endpoint
        
        // Create loadingHandler
        URLMockProtocol.loadingHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            switch request.url {
            case mainDishMockEndPoint.getURL():
                return (response, mainDishMockdata, nil)
            case detailMockEndPoint.getURL():
                return (response, dishDetailMockdata, nil)
            default:
                return (response, nil, nil)
            }
        }
        
        // Make networkManger with session for test
        let expectedMain = XCTestExpectation(description: "MainDish")
        let expectedDetail = XCTestExpectation(description: "DetailOfDish")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLMockProtocol.self]
        
        // Dependency injection
        sut = NetworkManager(session: URLSession(configuration: configuration))
        
        // Test request - main
        sut.request(endpoint: mainDishMockEndPoint) {(result: Result<SideDishInfo?, NetworkError>) in
            switch result {
            case .success(let result):
                XCTAssertEqual(result, expectedDecodedMain)
            case .failure(let error):
                XCTFail("Request was not successful: \(error.localizedDescription)")
            }
            expectedMain.fulfill()
        }
        
        // Test request - main
        sut.request(endpoint: detailMockEndPoint) {(result: Result<DetailDishInfo?, NetworkError>) in
            switch result {
            case .success(let result):
                XCTAssertEqual(result, expectedDecodedDetail)
            case .failure(let error):
                XCTFail("Request was not successful: \(error.localizedDescription)")
            }
            expectedDetail.fulfill()
        }
        
        wait(for: [expectedMain], timeout: 1)
        wait(for: [expectedDetail], timeout: 1)
    }
}
