//
//  SearchResultsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit

class SearchResultsController: ParentListViewController<Post> {
    let CELL_HEIGHT: CGFloat = 330
    weak final var delegate: RefetchDataDelegate?
    override var postArr: [Post] {
        didSet {
            tableView.contentSize = CGSize(width: self.view.bounds.size.width, height: CGFloat(postArr.count) * CELL_HEIGHT + 80)
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func configureUI() {
        super.configureUI()
        tableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: CardCell.self, identifier: CardCell.identifier)
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
        tableView.fill()
    }
    
    override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CardCell.identifier) as? CardCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = postArr[indexPath.row]
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
    
    override func executeAfterDragging() {
        if postArr.count > 0 {
            delegate?.didFetchData()
        }
    }
}
