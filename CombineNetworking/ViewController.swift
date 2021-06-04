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
            progressView.setProgress(progress, animated: false)
            progressLabel.text = String(format: "%.0f%%", progress * 100)
        }
    }
    
    private var cancellable: AnyCancellable?
    
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
        
        cancellable =
            URLSession.shared
            .downloadTaskPublisher(for: url)
            .receive(on: OperationQueue.main)
            .map { status -> Float in
                switch status {
                case let .downloading(percentage):
                    return Float(percentage)
                // Handle progress
                case let .complete(downloadResponse):
                // Handle response
                    return Float(1)
                }
            }
            .replaceError(with: 0)
            .assign(to: \.progress, on: self)
    }


}

