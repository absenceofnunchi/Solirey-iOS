//
//  FilterViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-30.
//

import UIKit

struct FilterSettings: Codable {
    let priceLimit: Float
    var itemIndexPath: IndexPath?
}

class FilterViewController: UIViewController, ModalConfigurable {
    var closeButton: UIButton!
    private var titleLabel: UILabel!
    private var sliderTitleLabel: UILabel!
    private var slider: UISlider!
    private var sliderTextLabel: UILabel!
    private var categoryTitleLabel: UILabel!
    private var selectedSliderValue: Float!
    private var selectedCategoryIndexPath: IndexPath! {
        didSet {
            collectionView.reloadData()
        }
    }
//    let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .light, scale: .small)
//    lazy var data: [MainMenu] = [
//        MainMenu(image: UIImage(systemName: "tv.circle")!.withConfiguration(configuration).withTintColor(.lightGray, renderingMode: .alwaysOriginal), title: Category.electronics.rawValue),
//        MainMenu(image: UIImage(systemName: "car.circle")!.withConfiguration(configuration).withTintColor(.lightGray, renderingMode: .alwaysOriginal), title: Category.vehicle.rawValue),
//        MainMenu(image: UIImage(systemName: "waveform.circle")!.withConfiguration(configuration).withTintColor(.lightGray, renderingMode: .alwaysOriginal), title: Category.digital.rawValue),
//        MainMenu(image: UIImage(systemName: "house.circle")!.withConfiguration(configuration).withTintColor(.lightGray, renderingMode: .alwaysOriginal), title: Category.realEstate.rawValue),
//        MainMenu(image: UIImage(systemName: "line.horizontal.3.decrease.circle")!.withConfiguration(configuration).withTintColor(.lightGray, renderingMode: .alwaysOriginal), title: Category.other.rawValue)
//    ]
    lazy private var data: [String] = [
        Category.electronics.asString(),
        Category.vehicle.asString(),
        Category.digital.asString(),
        Category.realEstate.asString(),
        Category.other.asString()
    ]
    
    private var collectionView: UICollectionView! = nil
    private let defaults = UserDefaults.standard
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
        if self.traitCollection.userInterfaceIdiom == .phone {
            self.modalPresentationStyle = .custom
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCloseButton()
        setButtonConstraints()
        configureUI()
        configureHierarchy()
        setConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let filterSettings = defaults.object(forKey: UserDefaultKeys.filterSettings) as? Data {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(FilterSettings.self, from: filterSettings) {
                let priceLimit = decoded.priceLimit
                slider.setValue(priceLimit, animated: true)
                if priceLimit == slider.maximumValue {
                    sliderTextLabel.text = "All items"
                } else if priceLimit == slider.minimumValue {
                    sliderTextLabel.text = "No item"
                } else {
                    sliderTextLabel.text = "Below \(Int(priceLimit)) ETH"
                }
                
                if let itemIndexPath = decoded.itemIndexPath {
                    selectedCategoryIndexPath = itemIndexPath
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            let filterSettings = FilterSettings(priceLimit: selectedSliderValue ?? slider.maximumValue, itemIndexPath: selectedCategoryIndexPath)
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(filterSettings) {
                defaults.set(encoded, forKey: UserDefaultKeys.filterSettings)
            }
        }
    }
}

extension FilterViewController {
    private func configureUI() {
        view.backgroundColor = .white
        
        titleLabel = createTitleLabel(text: "Filters")
        titleLabel.sizeToFit()
        view.addSubview(titleLabel)
        
        sliderTitleLabel = createTitleLabel(text: "Price Limit")
        sliderTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sliderTitleLabel)
        
        slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 50
        slider.isContinuous = true
        slider.tintColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1)
        slider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        
        UIView.animate(withDuration: 0.8) { [weak self] in
            self?.slider.setValue(80.0, animated: true)
        }
        
        sliderTextLabel = UILabel()
        sliderTextLabel.textColor = .gray
        sliderTextLabel.sizeToFit()
        sliderTextLabel.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(sliderTextLabel)
        
        categoryTitleLabel = createTitleLabel(text: "Categories")
        categoryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(categoryTitleLabel)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 60),
            
            sliderTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            sliderTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            sliderTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            slider.topAnchor.constraint(equalTo: sliderTitleLabel.bottomAnchor, constant: 15),
            slider.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            slider.heightAnchor.constraint(equalToConstant: 50),
            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            categoryTitleLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 20),
            categoryTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            categoryTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            categoryTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            collectionView.topAnchor.constraint(equalTo: categoryTitleLabel.bottomAnchor, constant: 0),
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func sliderValueDidChange(_ sender: UISlider) {
        let thumbRect = sender.thumbRect(forBounds: slider.bounds, trackRect: slider.trackRect(forBounds: slider.bounds), value: slider.value)
        let convertedThumbRect = slider.convert(thumbRect, to: view)

        sliderTextLabel.frame = CGRect(x: convertedThumbRect.origin.x - 25, y: convertedThumbRect.origin.y - 40, width: 200, height: 50)
        
        if sender.value == sender.maximumValue {
            sliderTextLabel.text = "All items"
        } else if sender.value == sender.minimumValue {
            sliderTextLabel.text = "No item"
        } else {
            self.selectedSliderValue = sender.value
            sliderTextLabel.text = "Below \(Int(sender.value)) ETH"
        }
    }
}

extension FilterViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.reuseIdentifier)
        collectionView.isScrollEnabled = false
        view.addSubview(collectionView)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(45))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
        let spacing = CGFloat(0)
        group.interItemSpacing = .fixed(spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCell.reuseIdentifier, for: indexPath as IndexPath) as! FilterCell
        let title = data[indexPath.row]
        cell.set(title: title)
        
        if indexPath == selectedCategoryIndexPath {
            cell.contentView.backgroundColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1)
            cell.titleLabel.textColor = .white
        } else {
            cell.contentView.backgroundColor = nil
            cell.titleLabel.textColor = .gray
        }
        
        return cell
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedCategoryIndexPath = indexPath
        if let cell = collectionView.cellForItem(at: indexPath) as? FilterCell {
            cell.contentView.backgroundColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1)
            cell.titleLabel.textColor = .white
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.selectedCategoryIndexPath = nil
        if let cell = collectionView.cellForItem(at: indexPath) as? FilterCell {
            cell.contentView.backgroundColor = nil
            cell.titleLabel.textColor = .gray
        }
    }
}

extension FilterViewController : UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = PartialPresentationController(presentedViewController: presented, presenting: presenting)
        return pc
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
