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
    private var saveBarButton: UIBarButtonItem!
    private var idCheckBarButton: UIBarButtonItem!
    final let db = FirebaseService.shared.db
    final var searchItems: [String]!
    final var lastSnapshot: QueryDocumentSnapshot!
    final let PAGINATION_LIMIT: Int = 20
    private let CELL_HEIGHT: CGFloat = 200
    private var customNavView: BackgroundView5!
    private var colorPatchView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBarTintColorToTheNavigationBar()
        configureSearchController()
        configureSearchBar()
        configureHierarchy()
        configureUI()
        setConstraints()
        configureOptionsBar()
    }
}

extension MainViewController {
    private func configureUI() {
        view.backgroundColor = .white
        extendedLayoutIncludesOpaqueBars = true
    }
    
    /// - Tag: TwoColumn
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .absolute(CELL_HEIGHT))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        let spacing = CGFloat(20)
        group.interItemSpacing = .fixed(spacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension MainViewController: UICollectionViewDelegate {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        collectionView.contentInset = UIEdgeInsets(top: 65, left: 0, bottom: 0, right: 0)
        collectionView.isScrollEnabled = true
        let height = CELL_HEIGHT * CGFloat(data.count / 2) + 350
        collectionView.contentSize = CGSize(width: view.bounds.size.width, height: height)
        collectionView.keyboardDismissMode = .onDrag
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        customNavView = BackgroundView5()
        customNavView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.addSubview(customNavView)
        
        colorPatchView.backgroundColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)
        colorPatchView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorPatchView)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            customNavView.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: -65),
            customNavView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 50),
            
            colorPatchView.topAnchor.constraint(equalTo: view.topAnchor, constant: -65),
            colorPatchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            colorPatchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            colorPatchView.bottomAnchor.constraint(equalTo: customNavView.topAnchor)
        ])
    }
}

extension MainViewController: UICollectionViewDataSource {
    final func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    final func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    // make a cell for each cell index path
    final func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.identifier, for: indexPath as IndexPath) as? CategoryCell else {
            fatalError()
        }
        
        let mainMenu = data[indexPath.row]
        cell.set(mainMenu: mainMenu)
        
        cell.buttonAction = { _ in
            
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    final func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        let mainMenu = data[indexPath.item]
        let mainDetailVC = MainDetailViewController()
        mainDetailVC.category = mainMenu.title
        self.navigationController?.pushViewController(mainDetailVC, animated: true)
    }
}

extension MainViewController {
    private func configureOptionsBar() {
        if #available(iOS 14.0, *) {
            let image = UIImage(systemName: "line.horizontal.3.decrease")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            let barButtonMenu = UIMenu(title: "", children: [
                UIAction(title: NSLocalizedString("Saved Items", comment: ""), image: UIImage(systemName: "star"), handler: menuHandler),
                UIAction(title: NSLocalizedString("Quick UI Check", comment: ""), image: UIImage(systemName: "barcode.viewfinder"), handler: menuHandler),
            ])
            optionsBarItem = UIBarButtonItem(title: nil, image: image, primaryAction: nil, menu: barButtonMenu)
            navigationItem.rightBarButtonItem = optionsBarItem
        } else {
            guard let saveImage = UIImage(systemName: "star")?.withTintColor(.white, renderingMode: .alwaysOriginal),
                  let idCheckImage = UIImage(systemName: "barcode.viewfinder")?.withTintColor(.white, renderingMode: .alwaysOriginal) else { return }
            
            saveBarButton = UIBarButtonItem(image: saveImage, style: .plain, target: self, action: #selector(buttonPressed(_:)))
            saveBarButton.tag = 0
            
            idCheckBarButton = UIBarButtonItem(image: idCheckImage, style: .plain, target: self, action: #selector(buttonPressed(_:)))
            idCheckBarButton.tag = 1
            
            navigationItem.rightBarButtonItems = [saveBarButton, idCheckBarButton]
        }
    }
    
    @objc private func menuHandler(action: UIAction) {        
        switch action.title {
            case "Saved Items":
                let savedVC = SavedViewController()
                self.navigationController?.pushViewController(savedVC, animated: true)
            case "Quick UI Check":
                let checkVC = QuickUICheckViewController()
                self.navigationController?.pushViewController(checkVC, animated: true)
            default:
                break
        }
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                let savedVC = SavedViewController()
                self.navigationController?.pushViewController(savedVC, animated: true)
            case 1:
                let checkVC = QuickUICheckViewController()
                self.navigationController?.pushViewController(checkVC, animated: true)
            default:
                break
        }
    }
}

extension MainViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let destinationViewController = animator.previewViewController else { return }
        animator.addAnimations { [weak self] in
            self?.show(destinationViewController, sender: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        func getPreviewVC(indexPath: IndexPath) -> UIViewController? {
            let mainMenu = data[indexPath.item]
            let mainDetailVC = MainDetailViewController()
            mainDetailVC.category = mainMenu.title
            return mainDetailVC
        }
        
        return UIContextMenuConfiguration(identifier: "DetailPreview" as NSString, previewProvider: { getPreviewVC(indexPath: indexPath) }) { _ in
            UIMenu(title: "", children: [])
        }
    }
}
