//
//  GridCollectionViewController.swift
//  CombineNetworking
//
//  Created by Michael Eid on 6/8/21.
//

import UIKit
import Combine

protocol GridCollectionView {
    var progress: Float { get set }
}

class GridCollectionViewController: UIViewController, GridCollectionView {
    var progress: Float = 0 {
        didSet {
            DispatchQueue.main.async {
                self.progressView.setProgress(self.progress, animated: false)
                self.progressLabel.text = String(format: "%.0f%%", self.progress * 100)
                self.progressLabel.isHidden = self.progress == 1
                self.progressView.isHidden = self.progress == 1
            }
        }
    }
    
    
    private var cancellables: Set<AnyCancellable> = []
    
    var images = [UIImage]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
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
    
    private  lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout())
        collectionView.register(GridCollectionViewCell.self, forCellWithReuseIdentifier: "GridCollectionViewCell")
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private func collectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        item.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(0.3))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        return UICollectionViewCompositionalLayout(section: section)
    }

    
    var shouldReload = false {
        didSet {
            collectionView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let url = URL(string: "https://picsum.photos/400")!

        let urls = [URL](repeating: url, count: 30)

        getImages(for: urls)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("ERROR")
                }
            }, receiveValue: { images in
                self.images = images.compactMap{ $0 }
            })
            .store(in: &cancellables)
        
        view.addSubview(collectionView)
        view.addSubview(progressView)
        view.addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
                                        progressView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                                        progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                        progressView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
                                        progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                        progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 15),
                                        
                                        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                                        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
    
    func createRequestProgress() -> Progress {
        let requestProgress = Progress.discreteProgress(totalUnitCount: 30)
        progressView.observedProgress = requestProgress
        requestProgress
            .publisher(for: \.fractionCompleted)
            .sink { [weak self] fractionCompleted -> Void in
                self?.progress = Float(fractionCompleted)
            }
            .store(in: &cancellables)
        return requestProgress
    }
    
    func getImage(for url: URL, progress: Progress? = nil) -> AnyPublisher<UIImage?, Never> {
        return URLSession.shared.dataTaskProgressPublisher(for: url, progress: progress)
            .map(\.data)
            .compactMap(UIImage.init)
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    func getImages(for urls: [URL]) -> AnyPublisher<[UIImage?], Error> {
        let requestProgress = createRequestProgress()
        return Publishers.Sequence(sequence: urls.map { getImage(for: $0, progress: requestProgress) })
            .flatMap(maxPublishers: .max(1)) { $0 }
            .collect()
            .eraseToAnyPublisher()
    }

}

extension GridCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCollectionViewCell", for: indexPath) as? GridCollectionViewCell {
            let image = images[indexPath.row]
            cell.imageView.image = image
            cell.backgroundColor = .systemTeal
            return cell
        }
        return UICollectionViewCell()
    }
}

