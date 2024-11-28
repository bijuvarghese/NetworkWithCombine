import Foundation
import Combine

// MARK: - Async Await Protocols
public enum NetworkError: Error {
    case allError
    case invalidUrl
    case jsonParsingFailed
    case serverError(statusCode: Int)
    case unknownError
}

public protocol NetworkManagerProtocol {
    func getData<T: Codable>(urlstr: String) -> Future<T, Error>
}

public protocol APIHandlerProtocol {
    func callAPI(url: URL) -> AnyPublisher<Data, Error>
}

public protocol ResponseHandlerProtocol {
    func parseResponse<T: Codable>(data: Data) -> Result<T, Error>
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
                switch completion {
                case .failure(let error):
                    promise(.failure(error))
                case .finished:
                    break
                }
            } receiveValue: { data in
                switch self.responseHandler.parseResponse(data: data) {
                case .success(let response):
                    promise(.success(response))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
            .store(in: &self.cancellables)
        }
    }
}

public class APIHandler: APIHandlerProtocol {
    
    public init() {}

    public func callAPI(url: URL) -> AnyPublisher<Data, Error> {
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { (data: Data, response: URLResponse) in
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        return data
                    case 400...499:
                        throw NetworkError.serverError(statusCode: httpResponse.statusCode)
                    case 500...599:
                        throw NetworkError.serverError(statusCode: httpResponse.statusCode)
                    default:
                        throw NetworkError.unknownError
                    }
                } else {
                    throw NetworkError.unknownError
                }
            }
            .eraseToAnyPublisher()
    }
}

public class ResponseHandler: ResponseHandlerProtocol {
    
    public init() {}
    
    public func parseResponse<T: Codable>(data: Data) -> Result<T, Error> {
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return .success(decodedData)
        } catch {
            return .failure(NetworkError.jsonParsingFailed)
        }
    }
}
