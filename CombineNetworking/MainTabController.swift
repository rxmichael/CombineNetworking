//
//  MainTabController.swift
//  CombineNetworking
//
//  Created by Michael Eid on 6/8/21.
//

import UIKit

class MainTabController: UITabBarController {
    
    
    override func viewDidLoad() {
        setupTabBar()
    }
    
    func setupTabBar() {
        let item = UITabBarItem(title: "File Progress", image: UIImage(systemName: "square.and.arrow.down.fill"), selectedImage: UIImage(systemName: "square.and.arrow.down"))

        let fileVc = ViewController()
        fileVc.tabBarItem = item
        
        let item2 = UITabBarItem(title: "Collection View", image: UIImage(systemName: "photo.fill.on.rectangle.fill"), selectedImage: UIImage(systemName: "photo.on.rectangle"))

        let gridVc = GridCollectionViewController()
        gridVc.tabBarItem = item2

        viewControllers = [fileVc, gridVc]
    }
}
