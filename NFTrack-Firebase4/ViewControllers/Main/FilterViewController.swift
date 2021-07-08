//
//  FilterViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-30.
//

import UIKit

class FilterViewController: UIViewController, ModalConfigurable {
    var closeButton: UIButton!
    private var titleLabel: UILabel!
    private var sliderTitleLabel: UILabel!
    private var underlineView: UnderlineView!
    private var slider: UISlider!
    private var sliderTextLabel: UILabel!
    private var selectedSliderValue: Float!
    private var selectedCategoryIndexPath: IndexPath! {
        didSet {
            collectionView.reloadData()
        }
    }
    private var toggleSwitchContainer: UIView!
    private var toggleSwitchLabel: UILabel!
    private var toggleSwitch: UISwitch!
    private var toggleValue: Bool!
    private var priceTitleLabel: UILabel!
    private var toggleSwitchSubContainer: UIView!
    private var dateTitleLabel: UILabel!
    private var dateContainer: UIView!
    private var dateSubcontainer: UIView!
    private var dateLabel: UILabel!
    private var dateToggleSwitch: UISwitch!
    private var dateToggleValue: Bool!
    var onDoneBlock: ((UIViewController) -> Void)!
    lazy private var data: [String] = Category.getAll()
    private var categoryTitleLabel: UILabel!
    private var underlineView3: UnderlineView!
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
                selectedSliderValue = priceLimit
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
                
                toggleSwitch.setOn(decoded.priceIsDescending, animated: true)
                toggleValue = decoded.priceIsDescending
                
                dateToggleSwitch.setOn(decoded.dateIsDescending, animated: true)
                dateToggleValue = decoded.dateIsDescending
            }
        } else {
            toggleValue = false
            dateToggleValue = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            let filterSettings = FilterSettings(priceLimit: selectedSliderValue ?? slider.maximumValue, itemIndexPath: selectedCategoryIndexPath, priceIsDescending: toggleValue, dateIsDescending: dateToggleValue)
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(filterSettings) {
                defaults.set(encoded, forKey: UserDefaultKeys.filterSettings)
            }
            /// refresh the search result
            self.onDoneBlock(self)
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
        
        underlineView = UnderlineView()
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(underlineView)
        
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
        
        priceTitleLabel = createTitleLabel(text: "Price")
        view.addSubview(priceTitleLabel)
        
        toggleSwitchContainer = UIView()
        toggleSwitchContainer.layer.cornerRadius = 8
        toggleSwitchContainer.layer.borderWidth = 0.5
        toggleSwitchContainer.layer.borderColor = UIColor.lightGray.cgColor
        toggleSwitchContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toggleSwitchContainer)
        
        toggleSwitchSubContainer = UIView()
        toggleSwitchSubContainer.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitchContainer.addSubview(toggleSwitchSubContainer)
        
        toggleSwitchLabel = UILabel()
        toggleSwitchLabel.font = UIFont.systemFont(ofSize: 15)
        toggleSwitchLabel.textColor = .lightGray
        toggleSwitchLabel.text = "Descending"
        toggleSwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitchSubContainer.addSubview(toggleSwitchLabel)
        
        toggleSwitch = UISwitch()
        toggleSwitch.onTintColor = .gray
        toggleSwitch.onTintColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1)
        toggleSwitch.addTarget(self, action: #selector(switchDidToggle), for: .valueChanged)
        toggleSwitch.tag = 1
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitchSubContainer.addSubview(toggleSwitch)
        
        dateTitleLabel = createTitleLabel(text: "Date")
        view.addSubview(dateTitleLabel)
        
        dateContainer = UIView()
        dateContainer.layer.cornerRadius = 8
        dateContainer.layer.borderWidth = 0.5
        dateContainer.layer.borderColor = UIColor.lightGray.cgColor
        dateContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dateContainer)
        
        dateSubcontainer = UIView()
        dateSubcontainer.translatesAutoresizingMaskIntoConstraints = false
        dateContainer.addSubview(dateSubcontainer)
        
        dateLabel = UILabel()
        dateLabel.font = UIFont.systemFont(ofSize: 15)
        dateLabel.textColor = .lightGray
        dateLabel.text = "Descending"
        dateLabel.sizeToFit()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateSubcontainer.addSubview(dateLabel)
        
        dateToggleSwitch = UISwitch()
        dateToggleSwitch.onTintColor = .gray
        dateToggleSwitch.onTintColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1)
        dateToggleSwitch.addTarget(self, action: #selector(switchDidToggle), for: .valueChanged)
        dateToggleSwitch.tag = 2
        dateToggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        dateSubcontainer.addSubview(dateToggleSwitch)
        
        categoryTitleLabel = createTitleLabel(text: "Categories")
        categoryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(categoryTitleLabel)
        
        underlineView3 = UnderlineView()
        underlineView3.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(underlineView3)
        underlineView3.setNeedsDisplay()
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 60),
            
            sliderTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            sliderTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            sliderTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            underlineView.topAnchor.constraint(equalTo: sliderTitleLabel.bottomAnchor),
            underlineView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            underlineView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            underlineView.heightAnchor.constraint(equalToConstant: 0.2),
            
            slider.topAnchor.constraint(equalTo: underlineView.bottomAnchor, constant: 15),
            slider.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            slider.heightAnchor.constraint(equalToConstant: 50),
            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            priceTitleLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 20),
            priceTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            priceTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            toggleSwitchContainer.topAnchor.constraint(equalTo: priceTitleLabel.bottomAnchor, constant: 5),
            toggleSwitchContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            toggleSwitchContainer.heightAnchor.constraint(equalToConstant: 80),
            toggleSwitchContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            toggleSwitchSubContainer.centerXAnchor.constraint(equalTo: toggleSwitchContainer.centerXAnchor),
            toggleSwitchSubContainer.centerYAnchor.constraint(equalTo: toggleSwitchContainer.centerYAnchor),
            toggleSwitchSubContainer.widthAnchor.constraint(equalToConstant: 140),
            
            toggleSwitchLabel.leadingAnchor.constraint(equalTo: toggleSwitchSubContainer.leadingAnchor),
            toggleSwitchLabel.heightAnchor.constraint(equalTo: toggleSwitchSubContainer.heightAnchor),
            
            toggleSwitch.leadingAnchor.constraint(equalTo: toggleSwitchLabel.trailingAnchor, constant: 5),
            toggleSwitch.heightAnchor.constraint(equalTo: toggleSwitchSubContainer.heightAnchor),
            
            dateTitleLabel.topAnchor.constraint(equalTo: toggleSwitchContainer.bottomAnchor, constant: 30),
            dateTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            dateTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            dateContainer.topAnchor.constraint(equalTo: dateTitleLabel.bottomAnchor, constant: 5),
            dateContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            dateContainer.heightAnchor.constraint(equalToConstant: 80),
            dateContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            dateSubcontainer.centerXAnchor.constraint(equalTo: dateContainer.centerXAnchor),
            dateSubcontainer.centerYAnchor.constraint(equalTo: dateContainer.centerYAnchor),
            dateSubcontainer.widthAnchor.constraint(equalToConstant: 140),
            
            dateLabel.leadingAnchor.constraint(equalTo: dateSubcontainer.leadingAnchor),
            dateLabel.heightAnchor.constraint(equalTo: dateSubcontainer.heightAnchor),
            
            dateToggleSwitch.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 5),
            dateToggleSwitch.heightAnchor.constraint(equalTo: dateSubcontainer.heightAnchor),
            
            categoryTitleLabel.topAnchor.constraint(equalTo: dateContainer.bottomAnchor, constant: 30),
            categoryTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            categoryTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            underlineView3.topAnchor.constraint(equalTo: categoryTitleLabel.bottomAnchor, constant: 0),
            underlineView3.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            underlineView3.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            underlineView3.heightAnchor.constraint(equalToConstant: 0.4),
            
            collectionView.topAnchor.constraint(equalTo: underlineView3.bottomAnchor, constant: 25),
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.93),
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
    
    @objc func switchDidToggle(_ sender: UISwitch) {
        switch sender.tag {
            case 1:
                toggleValue = sender.isOn
            case 2:
                dateToggleValue = sender.isOn
            default:
                break
        }
    }
    
    @objc func swiped() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension FilterViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
//        collectionView.allowsMultipleSelection = true
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

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let item = collectionView.cellForItem(at: indexPath) as! FilterCell
        if item.isSelected {
            selectedCategoryIndexPath = nil
            collectionView.deselectItem(at: indexPath, animated: true)
        } else {
            selectedCategoryIndexPath = indexPath
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            return true
        }
        
        return false
    }
}

extension FilterViewController : UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = PartialPresentationController(presentedViewController: presented, presenting: presenting, yCoordinate: UIScreen.main.bounds.size.height * 0.2)
        return pc
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
