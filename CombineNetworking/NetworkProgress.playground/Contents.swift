import UIKit
import Combine

var greeting = "Hello, playground"

private var cancellable: AnyCancellable?

let url = URL(string: "https://images.unsplash.com/photo-1554773228-1f38662139db")!

cancellable =
    URLSession.shared
    .downloadTaskPublisher(for: url)
    .receive(on: OperationQueue.main)
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                // Handle error
            }
        }) { downloadStatus in
            switch downloadStatus {
            case let .downloading(percentage):
                print("Percentage \(percentage)")
            // Handle progress
            case let .complete(downloadResponse):
            // Handle response
                print("Complete \(downloadResponse)")
            }
        }
