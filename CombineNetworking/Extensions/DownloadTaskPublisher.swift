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
            if let url = url, let response = response {
                // We have to move this file before returning from this closure. The original will be deleted the moment we return.
                // Try to maintain file extension from URLRequest.
                var targetURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)
                if let pathExtension = request.url?.pathExtension {
                    targetURL.appendPathExtension(pathExtension)
                }
                do {
                    try FileManager.default.moveItem(at: url, to: targetURL)
                    subject.send(.complete(response: DownloadResponse(fileURL: targetURL, response: response)))
                    subject.send(completion: .finished)
                } catch {
                    subject.send(completion: .failure(error))
                }
            } else if let error = error {
                subject.send(completion: .failure(error))
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

