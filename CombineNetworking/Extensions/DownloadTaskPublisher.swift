//
//  DownloadTaskPublisher.swift
//  CombineNetworking
//
//  Created by Michael Eid on 6/3/21.
//

import Foundation
import Combine

enum DownloadStatus {
    case downloading(percentage: Double)
    case complete(response: DownloadResponse)
}

public struct DownloadResponse {
    public var fileURL: URL
    public var response: URLResponse
}

extension URLSession {
    func downloadTaskPublisher(for url: URL) ->  AnyPublisher<DownloadStatus, Error> {
        let request = URLRequest(url: url)
        return downloadTaskPublisher(with: request)
    }
    
    func downloadTaskPublisher(with request: URLRequest) -> AnyPublisher<DownloadStatus, Error> {
        let subject = PassthroughSubject<DownloadStatus, Error>()
        let task = downloadTask(with: request) { url, response, error in
            guard error == nil else {
                subject.send(completion: .failure(error!))
                return
            }
            
            guard let response = response else {
                subject.send(completion: .failure(URLError(.badServerResponse)))
                return
            }

            guard let url = url else {
                subject.send(completion: .failure(URLError(.fileDoesNotExist)))
                return
            }
            
            do {
                guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
                let fileUrl = cacheDir.appendingPathComponent(UUID().uuidString)
                try FileManager.default.moveItem(atPath: url.path, toPath: fileUrl.path)
                subject.send(.complete(response: DownloadResponse(fileURL: fileUrl, response: response)))
                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .failure(error))
                return
            }
        }
        
        task.taskDescription = request.url?.absoluteString
            
        let receivedPublisher = task.publisher(for: \.countOfBytesReceived)
              .debounce(for: .seconds(0.01), scheduler: RunLoop.current) // adjust
             
        let expectedPublisher = task.publisher(for: \.countOfBytesExpectedToReceive, options: [.initial, .new])
        
        task.resume()
        return Publishers.CombineLatest(receivedPublisher, expectedPublisher)
            .map { .downloading(percentage: Double($0.0) / Double($0.1)) }
            .setFailureType(to: Error.self)
            .merge(with: subject)
            .eraseToAnyPublisher()
    }
  }

