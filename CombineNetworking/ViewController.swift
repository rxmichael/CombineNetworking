//
//  ViewController.swift
//  CombineNetworking
//
//  Created by Michael Eid on 6/3/21.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    @Published var progress: Float = 0 {
        didSet {
            DispatchQueue.main.async {
                self.progressView.setProgress(self.progress, animated: false)
                self.progressLabel.text = String(format: "%.0f%%", self.progress * 100)
            }
        }
    }
    
    private var cancellables =  Set<AnyCancellable>()
    
    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0"
        label.textAlignment = .center
        label.textColor = UIColor.purple
        label.font = UIFont.boldSystemFont(ofSize: 24)
        return label
    }()
    
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = UIColor.lightGray
        progressView.tintColor = UIColor.systemTeal
        return progressView
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.addSubview(progressView)
        view.addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
                                        progressView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                                        progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                        progressView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
                                        progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                        progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 15)])
        
        let url = URL(string: "https://images.unsplash.com/photo-1554773228-1f38662139db")!
        
        let progress = setupRequestProgress()
        
        URLSession.shared
            .downloadTaskPublisher(for: url, progress: progress)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error \(error)")
                }
            }, receiveValue: { response in
                print("\(response.fileURL)")
            })
            .store(in: &cancellables)
    }
    
    func setupRequestProgress() -> Progress {
        let requestProgress = Progress.discreteProgress(totalUnitCount: 1)
        progressView.observedProgress = requestProgress
        requestProgress
            .publisher(for: \.fractionCompleted)
            .map { Float($0) }
            .assign(to: \.progress, on: self)
            .store(in: &cancellables)
        return requestProgress
    }


}

