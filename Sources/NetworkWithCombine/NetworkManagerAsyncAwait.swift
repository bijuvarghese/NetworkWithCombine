//
//  File.swift
//  
//
//  Created by Biju Varghese on 6/16/23.
//

import Foundation
import Combine

public protocol NetworkManagerProtocolAsyncAwait {
    func getData<T: Codable>(urlstr: String) async -> AnyPublisher<T, any Error>
}

public protocol APIHandlerProtocolAsyncAwait {
    func callAPI(url: URL) async ->  AnyPublisher<Data, any Error>
}
public protocol ResponseHandlerProtocolAsyncAwait {
    func parseResponse<T: Codable>(from publisher: AnyPublisher<Data, any Error>) async ->  AnyPublisher<T, any Error>
}

// MARK: - Async Await
public struct NetworkManagerAsyncAwait<T: Codable>: NetworkManagerProtocolAsyncAwait {
    
    private var apiHandler: APIHandlerProtocolAsyncAwait
    private var responseHandler: ResponseHandlerProtocolAsyncAwait
    
    public init(apiHandler: APIHandlerProtocolAsyncAwait, responseHandler: ResponseHandlerProtocolAsyncAwait) {
        self.apiHandler = apiHandler
        self.responseHandler = responseHandler
    }
    
    public func getData<T: Codable>(urlstr: String) async -> AnyPublisher<T, any Error> {
        guard let url = URL(string: urlstr) else {
            return AnyPublisher(Fail<T, any Error>(error: NetworkError.invalidUrl))
        }
        let data = await apiHandler.callAPI(url: url)
        let response: AnyPublisher<T, any Error> = await responseHandler.parseResponse(from: data)
        return response
    }
}


public class APIHandlerAsyncAwait : APIHandlerProtocolAsyncAwait {
    
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

public class ResponseHandlerAsyncAwait: ResponseHandlerProtocolAsyncAwait {
    
    public init() {
        
    }
    
    public func parseResponse<T: Codable>(from publisher: AnyPublisher<Data, any Error>) async ->  AnyPublisher<T, any Error> {
        let response = publisher.decode(type: T.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        return response
    }
    
}
