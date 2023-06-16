import Foundation
import Combine

// MARK: - Protocols
public enum NetworkError: Error {
    case allError
    case failedUrlCreation
    case testJsonUrl
    case testjsonparse
}

public protocol NetworkManagerProtocol {
    func getData<T: Codable>(urlstr: String) async -> AnyPublisher<T, any Error>
}

public protocol APIHandlerProtocol {
    func callAPI(url: URL) async ->  AnyPublisher<Data, any Error>
}
public protocol ResponseHandlerProtocol {
    func parseResponse<T: Codable>(from publisher: AnyPublisher<Data, any Error>) async ->  AnyPublisher<T, any Error>
}

// MARK: - Concrete 
public struct NetworkManager<T: Codable>: NetworkManagerProtocol {
    
    private var apiHandler: APIHandlerProtocol
    private var responseHandler: ResponseHandlerProtocol
    
    public init(apiHandler: APIHandlerProtocol, responseHandler: ResponseHandlerProtocol) {
        self.apiHandler = apiHandler
        self.responseHandler = responseHandler
    }
    
    public func getData<T: Codable>(urlstr: String) async -> AnyPublisher<T, any Error> {
        guard let url = URL(string: urlstr) else {
            return AnyPublisher(Fail<T, any Error>(error: NetworkError.failedUrlCreation))
        }
        let data = await apiHandler.callAPI(url: url)
        let response: AnyPublisher<T, any Error> = await responseHandler.parseResponse(from: data)
        return response
    }
}


public class APIHandler : APIHandlerProtocol {
    
    private var cancellables = [AnyCancellable]()

    public init() {

    }
    
    public func callAPI(url: URL) async ->  AnyPublisher<Data, any Error> {
        let session = URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { (data: Data, response: URLResponse) in
                if let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) {
                    return data
                }
                throw NetworkError.allError
            }
            .eraseToAnyPublisher()
        return session
    }
}

public class ResponseHandler: ResponseHandlerProtocol {
    

    public init() {
        
    }
    
    public func parseResponse<T: Codable>(from publisher: AnyPublisher<Data, any Error>) async ->  AnyPublisher<T, any Error> {
        let response = publisher.decode(type: T.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        return response
    }
    
}





//
//public protocol NetworkManagerFutureProtocol {
//    func getData<T: Codable>(urlstr: String) -> Future<T, NetworkError>
//}
//
//struct NetworkManagerFuture<T: Codable>: NetworkManagerFutureProtocol {
//
//    var apiHandler: APIHandlerFuture
//    var responseHandler: ResponseHandlerFuture
//
//    init(apiHandler: APIHandlerFuture, responseHandler: ResponseHandlerFuture) {
//        self.apiHandler = apiHandler
//        self.responseHandler = responseHandler
//    }
//
//    func getData<T: Codable>(urlstr: String) -> Future<T, NetworkError> {
//        let f: Future<T, NetworkError> = Future() { promise in
//            guard let url = URL(string: urlstr) else {
//                promise(.failure(.failedUrlCreation))
//                return
//            }
//            let data = apiHandler.callAPI(url: url)
//            let response: Future<T, NetworkError> = responseHandler.parseResponse(from: data)
//            return response
//        }
//    }
//}
//
//class APIHandlerFuture {
//    func callAPI(url: URL) ->  AnyPublisher<Data, any Error> {
//        let ses = URLSession.shared.dataTaskPublisher(for: url)
//            .tryMap { (data: Data, response: URLResponse) in
//                if let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) {
//                    return data
//                }
//                throw NetworkError.allError
//            }
//            .eraseToAnyPublisher()
//        return ses
//    }
//}
//
//class ResponseHandlerFuture {
//    func parseResponse<T: Codable>(from publisher: AnyPublisher<Data, any Error>) ->  Future<T, NetworkError> {
//        return Future() { promise in
//            let response = publisher.decode(type: T.self, decoder: JSONDecoder())
//                .receive(on: DispatchQueue.main)
//                .sink { status in
//                    switch status {
//                    case .finished:
//                        debugPrint("Finished")
//                    case .failure(let error):
//                        promise(.failure(.allError))
//                    }
//                } receiveValue: { response in
//                    promise(.success(response))
//                }
//
//
//        }
//    }
//
//}
