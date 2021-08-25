//
//  ImagePreviewViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-08.
//

import UIKit
import QuickLook

// to distinguish the sections when displayed
// however, no sections are being implemented at the moment
// remote image is to display images right at then moment when the cell is being dequeued. TangibleListEditVC uses this since it's displaying the images in Firestore Storage
// whereas the normal "image" enum is used when local images are used such as PostVC
enum Header: Int, CaseIterable {
    case image, document, remoteImage
    func asString() -> String {
        switch self {
            case .image, .remoteImage:
                return NSLocalizedString("Images", comment: "")
            case .document:
                return NSLocalizedString("Documents", comment: "")
        }
    }
}

struct PreviewData {
    let header: Header
    let filePath: URL
}

class ImagePreviewViewController: UIViewController {
    var data: [PreviewData]! = [] {
        didSet {
            guard let collectionView = collectionView else { return }
            if data.count > 0 {
                data = NSOrderedSet(array: data).array as? [PreviewData]
            }
            collectionView.reloadData()
        }
    }
    
    weak var delegate: DeletePreviewDelegate?
    var collectionView: UICollectionView! = nil
    var postType: PostType!
    var loadingIndicator: UIActivityIndicatorView!
    // to be used for BigPreviewVC after fetching the image data from Firebase Storage
    var remoteImageData: Data!
    init(postType: PostType) {
        super.init(nibName: nil, bundle: nil)
        self.postType = postType
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingIndicator = UIActivityIndicatorView()
        configureHierarchy()
        setConstraints()
    }
    
    deinit {
        deleteAllLocalFiles()
    }
}

extension ImagePreviewViewController {
    /// - Tag: TwoColumn
    private func createLayout(postType: PostType) -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        var group: NSCollectionLayoutGroup!
        switch postType {
            case .tangible:
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9),
                                                       heightDimension: .absolute(80))
                group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
            case .digital:
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.95),
                                                       heightDimension: .absolute(170))
                group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
                group.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: NSCollectionLayoutSpacing.fixed(5), top: .none, trailing: .none, bottom: .none)
        }
        
        let spacing = CGFloat(0)
        group.interItemSpacing = .fixed(spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension ImagePreviewViewController: UICollectionViewDelegate {
    private func configureHierarchy() {
        if collectionView == nil {
            collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout(postType: postType))
        }
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
//        collectionView.register(ImagePreviewHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ImagePreviewHeaderView.identifier)
        collectionView.isScrollEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        view.addSubview(collectionView)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension ImagePreviewViewController: UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath as IndexPath) as? ImageCell else {
            fatalError("ImageCell fatal error")
        }
        
        let header = data[indexPath.row].header
        let filePath = data[indexPath.row].filePath
                
        switch header {
            case .image:
                if let image = UIImage(contentsOfFile: "\(filePath.path)") {
                    cell.imageView.image = image
                }
            case .document:
                generateThumbnail(fileAt: filePath) { (image) in
                    DispatchQueue.main.async {
                        cell.imageView.image = image
                    }
                }
            case .remoteImage:
                cell.contentView.insertSubview(loadingIndicator, belowSubview: cell.closeButton)
                loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    loadingIndicator.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    loadingIndicator.centerXAnchor.constraint(equalTo: cell.centerXAnchor)
                ])
                
                loadingIndicator.startAnimating()
                cell.imageView.setImage(from: filePath) { [weak self] imageData in
                    // to be used for enlargement
                    self?.remoteImageData = imageData
                    self?.loadingIndicator.stopAnimating()
                }
        }
        
        cell.buttonAction = { [weak self] _ in
            self?.deletePreviewImage(indexPath: indexPath)
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        print("You selected cell #\(indexPath.item)!")
    }
    
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ImagePreviewHeaderView.identifier, for: indexPath) as? ImagePreviewHeaderView else {
//            fatalError("Header view error")
//        }
//
//        let header = Header.allCases[indexPath.section]
//        print("header.asString()", header.asString())
//        headerView.titleLabel.text = header.asString()
//
//        return headerView
//    }
}

extension ImagePreviewViewController {
    // MARK: - loadImageFromDiskWith
    private func loadImageFromDiskWith(fileName: String) -> UIImage? {
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        
        if let dirPath = paths.first {
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
            let image = UIImage(contentsOfFile: imageUrl.path)
            return image
        }
        
        return nil
    }
    
    // MARK: - delete file
    private func deleteLocalFile(filePath : URL) -> Bool{
//        let fileManager = FileManager.default
//        let docDir = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
//        let filePath = docDir.appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: filePath)
            print("File deleted")
            return true
        }
        catch {
            print("Error")
        }
        return false
    }
    
    func generateThumbnail(fileAt: URL, completion: @escaping (UIImage) -> Void) {
        // 1
        let size = CGSize(width: 128, height: 102)
        let scale = UIScreen.main.scale
        // 2
        let request = QLThumbnailGenerator.Request(
            fileAt: fileAt,
            size: size,
            scale: scale,
            representationTypes: .all)
        
        // 3
        let generator = QLThumbnailGenerator.shared
        generator.generateBestRepresentation(for: request) { thumbnail, error in
            if let thumbnail = thumbnail {
                completion(thumbnail.uiImage)
            } else if let error = error {
                // Handle error
                print(error)
            }
        }
    }
    
    private func deleteAllLocalFiles() {
        let fileManager = FileManager.default
        let documentsUrl =  fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first! as NSURL
        let documentsPath = documentsUrl.path
        
        do {
            if let documentPath = documentsPath
            {
                let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
                print("all files in cache: \(fileNames)")
                for fileName in fileNames {
                    
                    if (fileName.hasSuffix(".png"))
                    {
                        let filePathName = "\(documentPath)/\(fileName)"
                        try fileManager.removeItem(atPath: filePathName)
                    }
                }
                
                let files = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
                print("all files in cache after deleting images: \(files)")
            }
            
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    private func deletePreviewImage(indexPath: IndexPath) {
        let filePath = data[indexPath.row].filePath
        self.collectionView.deleteItems(at: [indexPath])
        self.data.remove(at: indexPath.row)
        let _ = self.deleteLocalFile(filePath: filePath)
        self.delegate?.didDeleteFileFromPreview(filePath: filePath)
    }
}

extension ImagePreviewViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        func getPreviewVC(indexPath: IndexPath) -> UIViewController? {
            let bigVC = BigPreviewViewController()
            let filePath = data[indexPath.row].filePath
            var image: UIImage!
            
            switch data[indexPath.row].header {
                case .remoteImage:
                    image = UIImage(data: remoteImageData)
                default:
                    image = UIImage(contentsOfFile: "\(filePath.path)")
            }
            
            bigVC.imageView.image = image
            return bigVC
        }
        
        let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] action in
            self?.deletePreviewImage(indexPath: indexPath)
        }
        
        return UIContextMenuConfiguration(identifier: "DetailPreview" as NSString, previewProvider: { getPreviewVC(indexPath: indexPath) }) { _ in
            UIMenu(title: "", children: [deleteAction])
        }
    }
}
