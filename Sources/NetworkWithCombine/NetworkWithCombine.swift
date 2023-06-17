import Foundation
import Combine

// MARK: - Async Await Protocols
public enum NetworkError: Error {
    case allError
    case invalidUrl
    case jsonParsingFailed
}

public protocol NetworkManagerProtocol {
    func getData<T: Codable>(urlstr: String) -> Future<T, Error>
}

public protocol APIHandlerProtocol {
    func callAPI(url: URL) -> AnyPublisher<Data, Error>
}
public protocol ResponseHandlerProtocol {
    func parseResponse<T: Codable>(data: Data) -> T?
}

// MARK: - Concrete
public class NetworkManager<T: Codable>: NetworkManagerProtocol {
    
    private var apiHandler: APIHandlerProtocol
    private var responseHandler: ResponseHandlerProtocol
    private var cancellables = [AnyCancellable]()

    public init(apiHandler: APIHandlerProtocol, responseHandler: ResponseHandlerProtocol) {
        self.apiHandler = apiHandler
        self.responseHandler = responseHandler
    }
    
    public func getData<T: Codable>(urlstr: String) -> Future<T, Error> {
        return Future { promise in
            guard let url = URL(string: urlstr) else {
                return promise(.failure(NetworkError.invalidUrl))
            }
            let data = self.apiHandler.callAPI(url: url)
            data.sink { completion in
                if case .failure(let error) = completion {
                    return promise(.failure(error))
                }
            } receiveValue: { data in
                // Caller must provide T as its generic class
                if let response: T = self.responseHandler.parseResponse(data: data) {
                    return promise(.success(response))
                } else {
                    return promise(.failure(NetworkError.jsonParsingFailed))
                }
            }
            .store(in: &self.cancellables)
        }
    }
}


public class APIHandler: APIHandlerProtocol {
    
    public init() {
        
    }

    public func callAPI(url: URL) -> AnyPublisher<Data, Error> {
        return URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { (data: Data, response: URLResponse) in
                    if let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) {
                        return data
                    } else {
                        throw NetworkError.allError
                    }
                }
                .eraseToAnyPublisher()
        
    }
    
}

public class ResponseHandler: ResponseHandlerProtocol {
    
    public init() {
        
    }
    
    public func parseResponse<T: Codable>(data: Data) -> T? {
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
