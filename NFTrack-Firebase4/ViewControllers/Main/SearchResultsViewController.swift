//
//  SearchResultsViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-22.
//

import UIKit

class SearchResultsController: UITableViewController {
    var data = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

extension SearchResultsController {
    func configureTableView() {
        tableView.backgroundColor = .systemBackground
        tableView.register(ListCell.self, forCellReuseIdentifier: Cell.listCell)
        tableView.rowHeight = 100
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Cell.mainCell)
//        tableView.separatorStyle = .none
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.listCell, for: indexPath) as? ListCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none

        let title = data[indexPath.row].title
        let date = data[indexPath.row].date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: date)
        
        cell.set(title: title, date: formattedDate)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = data[indexPath.row]
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
}


extension UISearchController {
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let presentingVC = self.presentingViewController {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.view.frame = presentingVC.view.frame
            }
        }
    }
}
