import XCTest
import Combine
@testable import NetworkWithCombine

final class NetworkWithCombineTests: XCTestCase {
    var cancellables = [AnyCancellable]()
    
//    func testNetworkWithExpectionLoading() throws {
//        let expectation = XCTestExpectation(description: "calling network")
//        Task {
//            let nw: NetworkManager<Product> = NetworkManager(apiHandler: MockAPIHandler(), responseHandler: MockResponseHandler())
//            let t: AnyPublisher<Product, any Error> = await nw.getData(urlstr: "https://dummyjson.com/products/1")
//            t.sink(receiveCompletion: { error in
//                print(error)
//            }, receiveValue: { item in
//                XCTAssertEqual(item.id, 1)
//                expectation.fulfill()
//            })
//            .store(in: &cancellables)
//        }
//
//    }
    
    func testNetworkSuccess() throws {
        let nw: NetworkManager<Product> = NetworkManager(apiHandler: MockAPIHandler(), responseHandler: MockResponseHandler())
        let t: Future<Product, Error> = nw.getData(urlstr: "https://dummyjson.com/products/1")
        let vsyp: ValueSpy = ValueSpy(publisher: t)
        XCTAssertEqual(vsyp.products.first?.id ?? 0, 1)
    }
    
    func testNetworkError() throws {
        let mockAPI = MockAPIHandler()
        mockAPI.errorMode = .allError
        let nw: NetworkManager<Product> = NetworkManager(apiHandler: mockAPI, responseHandler: MockResponseHandler())
        let t: Future<Product, Error> = nw.getData(urlstr: "https://dummyjson.com/products/1")
        let vsyp: ValueSpy = ValueSpy(publisher: t)
        XCTAssertNil(vsyp.products.first)
    }

}


class MockAPIHandler: APIHandlerProtocol {
    
    var errorMode: NetworkError?
    var passthrough = PassthroughSubject<Data, any Error>()
    
    func callAPI(url: URL) -> AnyPublisher<Data, Error> {
        let helper = TestHelper()
        if let errorMode = errorMode {
            passthrough.send(completion: .failure(errorMode))
            return passthrough.eraseToAnyPublisher()
        }
        return helper.loadData(fileName: "product")
    }
}

class MockResponseHandler: ResponseHandlerProtocol {
    
    func parseResponse<T>(data: Data) -> T? where T : Decodable, T : Encodable {
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
}

struct Product: Codable {
    let id: Int?
    let title, description: String?
    let price: Int?
    let discountPercentage, rating: Double?
    let stock: Int?
    let brand, category: String?
    let thumbnail: String?
    let images: [String]?
}



class TestHelper {
    
    func loadData(fileName: String, ofType: String = "json") -> AnyPublisher<Data, any Error> {
        return Bundle.module.url(forResource: fileName, withExtension: ofType)
            .publisher
            .tryMap{ string in
                guard let data = try? Data(contentsOf: string) else {
                    fatalError("Failed to load \(string) from bundle.")
                }
                return data
            }
            .mapError { error in
                return error
            }
            .eraseToAnyPublisher()
        
    }
    
}

class ValueSpy {
    var cancellable: AnyCancellable?
    var products = [Product]()
    init(publisher: Future<Product, Error>) {
        cancellable = publisher
            .sink { status in
                
            } receiveValue: { [weak self] product in
                print(product)
                self?.products.append(product)
            }
    }
}
