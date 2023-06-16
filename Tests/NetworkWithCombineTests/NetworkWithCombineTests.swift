import XCTest
import Combine
@testable import NetworkWithCombine

final class NetworkWithCombineTests: XCTestCase {
    var cancellables = [AnyCancellable]()
    func testNetworkWithExpectionLoading() throws {
        let expectation = XCTestExpectation(description: "calling network")
        
        Task {
            let nw: NetworkManager<Product> = NetworkManager(apiHandler: MockAPIHandler(), responseHandler: MockResponseHandler())
            let t: AnyPublisher<Product, any Error> = await nw.getData(urlstr: "https://dummyjson.com/products/1")
            t.sink(receiveCompletion: { error in
                print(error)
            }, receiveValue: { item in
                XCTAssertEqual(item.id, 1)
                expectation.fulfill()
            })
            .store(in: &cancellables)
        }
        wait(for: [expectation], timeout: 10)
        
    }
    
    func testNetworkWithExpectionLoading2() throws {
        
        Task {
            let nw: NetworkManager<Product> = NetworkManager(apiHandler: MockAPIHandler(), responseHandler: MockResponseHandler())
            let t: AnyPublisher<Product, any Error> = await nw.getData(urlstr: "https://dummyjson.com/products/1")
            let vsyp = ValueSpy(publisher: t)
            XCTAssertEqual(vsyp.products.first?.id ?? 0, 1)
        }
        
        
    }
    
    
}


class MockAPIHandler: APIHandlerProtocol {
    func callAPI(url: URL) async -> AnyPublisher<Data, Error> {
        let helper = TestHelper()
        return helper.loadData(fileName: "product")
    }
    
    
}

class MockResponseHandler: ResponseHandlerProtocol {
    var cancel = [AnyCancellable]()
    func parseResponse<T: Codable>(from publisher: AnyPublisher<Data, Error>) -> AnyPublisher<T, any Error> {
        let v = publisher
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
        
        return v
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
    init(publisher: AnyPublisher<Product, any Error>) {
        cancellable = publisher.sink { status in
            
        } receiveValue: { [weak self] product in
            self?.products.append(product)
        }
    }
}
