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
        MainMenu(image: UIImage(named: "electronics")!, title: Category.electronics.rawValue),
        MainMenu(image: UIImage(named: "car")!, title: Category.vehicle.rawValue),
        MainMenu(image: UIImage(named: "real estate")!, title: Category.realEstate.rawValue),
        MainMenu(image: UIImage(named: "kayak")!, title: Category.other.rawValue)
    ]
    private var searchController: UISearchController!
    private var searchResultsController: SearchResultsController!
    private var collectionView: UICollectionView! = nil
    private let alert = Alerts()
    private var category: String! = "Electronics"
    private var searchItems = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar(vc: self)
        configureNavigationBar()
        configureSearchController()
        configureSearchBar()
        configureHierarchy()
        setConstraints()
    }
}

extension MainViewController: UISearchBarDelegate, UISearchControllerDelegate {
    func configureNavigationBar() {
        guard let starImage = UIImage(systemName: "star") else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        let barButtonItem = UIBarButtonItem(image: starImage.withTintColor(.gray, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(buttonPressed))
        self.navigationItem.rightBarButtonItem = barButtonItem
    }
    
    @objc func buttonPressed() {
        let savedVC = SavedViewController()
        self.navigationController?.pushViewController(savedVC, animated: true)
    }
    
    // configure search controller
    func configureSearchController() {
        searchResultsController = SearchResultsController()
        let nav = UINavigationController(rootViewController: searchResultsController)        
        searchController = UISearchController(searchResultsController: nav)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
//        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        
        definesPresentationContext = true
        navigationItem.searchController = searchController
    }
    
    func configureSearchBar() {
        // search bar attributes
        let searchBar = searchController!.searchBar
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.tintColor = .black
        searchBar.searchBarStyle = .minimal
        searchBar.scopeButtonTitles = [Category.electronics.rawValue, Category.vehicle.rawValue, Category.realEstate.rawValue, Category.other.rawValue]
        
        // search text field attributes
        let searchTextField = searchBar.searchTextField
        searchTextField.borderStyle = .roundedRect
        searchTextField.layer.cornerRadius = 8
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1).cgColor
        searchTextField.textColor = .gray
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Enter Search Here", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
    }
    
    // MARK: - searchBarSearchButtonClicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchController.searchBar.text else { return }

        // Strip out all the leading and trailing spaces.
        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString = text.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
        searchItems = strippedString.components(separatedBy: " ") as [String]
        
        fetchData(category: category)
        
        searchBar.resignFirstResponder()
    }
    
    func fetchData(category: String) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.searchResultsController.postArr.removeAll()
            FirebaseService.shared.db.collection("post")
                .whereField("tags", arrayContainsAny: self!.searchItems)
                .whereField("category", isEqualTo: category)
                .order(by: "date", descending: true)
                .getDocuments {(querySnapshot, err) in
                    if let err = err {
                        self?.alert.showDetail("Error fetching data", with: err.localizedDescription, for: self)
                    }
                    
                    defer {
                        DispatchQueue.main.async {
                            self?.searchResultsController.tableView.reloadData()
                        }
                    }
                    
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        DispatchQueue.main.async {
                            self?.searchResultsController.postArr = data
                        }
                    }
                }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if let selectedCategory = Category.getCategory(num: selectedScope), searchItems.count > 0 {
            self.category = selectedCategory.rawValue
            fetchData(category: self.category)
        }
//        updateSearchResults(for: searchController)
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
                                               heightDimension: .fractionalHeight(0.3))
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
    func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        collectionView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        collectionView.contentOffset = CGPoint(x: 0, y: -64)
        collectionView.isScrollEnabled = false
        view.addSubview(collectionView)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            collectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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
