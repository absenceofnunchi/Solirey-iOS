//
//  MainViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-21.
//

import UIKit
import FirebaseFirestore

struct MainMenu {
    let image: UIImage
    let title: String
}

class MainViewController: UIViewController {
    private let data = [
        MainMenu(image: UIImage(named: "electronics")!, title: Category.electronics.asString()),
        MainMenu(image: UIImage(named: "car")!, title: Category.vehicle.asString()),
        MainMenu(image: UIImage(named: "digital")!, title: Category.digital.asString()),
        MainMenu(image: UIImage(named: "real estate")!, title: Category.realEstate.asString()),
        MainMenu(image: UIImage(named: "kayak")!, title: Category.other.asString())
    ]
    final var searchController: UISearchController!
    final var searchResultsController: SearchResultsController!
    private var collectionView: UICollectionView! = nil
    final let alert = Alerts()
    final var category: ScopeButtonCategory! = .latest
    private var optionsBarItem: UIBarButtonItem!
    final let db = FirebaseService.shared.db
    final var searchItems: [String]!
    final var lastSnapshot: QueryDocumentSnapshot!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar(vc: self)
        configureSearchController()
        configureSearchBar()
        configureHierarchy()
        setConstraints()
        configureOptionsBar()
    }
}

extension MainViewController {
    /// - Tag: TwoColumn
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(200))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        let spacing = CGFloat(20)
        group.interItemSpacing = .fixed(spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension MainViewController: UICollectionViewDelegate {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        collectionView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        collectionView.contentOffset = CGPoint(x: 0, y: -64)
        collectionView.isScrollEnabled = true
        let height = CGFloat(200 * (data.count / 2) + 300)
        collectionView.contentSize = CGSize(width: view.bounds.size.width, height: height)
        view.addSubview(collectionView)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            collectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension MainViewController: UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.identifier, for: indexPath as IndexPath) as! CategoryCell
        
        let mainMenu = data[indexPath.row]
        cell.set(mainMenu: mainMenu)
        
        cell.buttonAction = { _ in
            
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        let mainMenu = data[indexPath.item]
        let mainDetailVC = MainDetailViewController()
        mainDetailVC.category = mainMenu.title
        self.navigationController?.pushViewController(mainDetailVC, animated: true)
    }
}

extension MainViewController {
    private func configureOptionsBar() {
        let barButtonMenu = UIMenu(title: "", children: [
            UIAction(title: NSLocalizedString("Saved Items", comment: ""), image: UIImage(systemName: "square.grid.2x2"), handler: menuHandler),
            UIAction(title: NSLocalizedString("Quick UI Check", comment: ""), image: UIImage(systemName: "c.circle"), handler: menuHandler),
        ])
        
        let image = UIImage(systemName: "line.horizontal.3.decrease")?.withRenderingMode(.alwaysOriginal)
        if #available(iOS 14.0, *) {
            optionsBarItem = UIBarButtonItem(title: nil, image: image, primaryAction: nil, menu: barButtonMenu)
            navigationItem.rightBarButtonItem = optionsBarItem
        } else {
            optionsBarItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(menuHandler(action:)))
            navigationItem.rightBarButtonItem = optionsBarItem
            print("below iOS 14")
        }
    }
    
    @objc private func menuHandler(action: UIAction) {
        
//        switch action.title {
//            case "Saved Items":
//                let savedVC = SavedViewController()
//                self.navigationController?.pushViewController(savedVC, animated: true)
//            case "Quick UI Check":
//                let checkVC = QuickUICheckViewController()
//                self.navigationController?.pushViewController(checkVC, animated: true)
//            default:
//                break
//        }
    }
}
