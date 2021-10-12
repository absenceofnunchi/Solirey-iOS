//
//  SceneDelegate.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-04.
//

import UIKit
import FirebaseAuth
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate, FetchUserConfigurable {
    var window: UIWindow?
    var storage = Set<AnyCancellable>()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
                
        CacheService.shared.removeAllObjects()
        if let windowScene = scene as? UIWindowScene {
            self.window = UIWindow(windowScene: windowScene)
            Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
                if let user = user {
                    self?.didSignIn(user)
                } else {
                    self?.window?.rootViewController = SignInViewController()
                }
                
                self?.window?.makeKeyAndVisible()
            }
        }
    }
    
    private func didSignIn(_ user: User) {
        UserDefaults.standard.set(user.uid, forKey: UserDefaultKeys.userId)
        UserDefaults.standard.set(user.displayName, forKey: UserDefaultKeys.displayName)
        
        if let photoURL = user.photoURL {
            let photoURL = "\(String(describing: photoURL))"
            UserDefaults.standard.set(photoURL, forKey: UserDefaultKeys.photoURL)
        } else {
            UserDefaults.standard.set(nil, forKey: UserDefaultKeys.photoURL)
        }
        
        Future<UserInfo, PostingError> { [weak self] promise in
            self?.fetchUserData(userId: user.uid, promise: promise)
        }
        .sink { (completion) in
            print(completion)
        } receiveValue: { (userInfo) in
            guard let address = userInfo.shippingAddress?.address,
                  let memberSince = userInfo.memberSince else { return }
            UserDefaults.standard.set(address, forKey: UserDefaultKeys.address)
            UserDefaults.standard.set(memberSince, forKey: UserDefaultKeys.memberSince)
        }
        .store(in: &storage)
        
        //                    var urlString: String!
        //
        //                    if user.photoURL != nil {
        //                        urlString = "\(user.photoURL!)"
        //                    } else {
        //                        urlString = "NA"
        //                    }
        //
        //                    FirebaseService.shared.db.collection("user").document(user.uid).setData([
        //                        "photoURL": urlString!,
        //                        "displayName": user.displayName ?? "No name",
        //                        "uid": user.uid
        //                    ], completion: { (error) in
        //                        if let error = error {
        //                            print("error updating profile", error.localizedDescription)
        //                        }
        //                    })
        
        let tabBarVC = CustomTabBarViewController()
        
        let mainVC = MainViewController()
        mainVC.title = "Main"
        
        let mainNav = UINavigationController(rootViewController: mainVC)
        window?.backgroundColor = .white
        mainNav.view.alpha = 0
        
        let listVC = ListViewController()
        listVC.title = "List"
        
        let listNav = UINavigationController(rootViewController: listVC)
        
        let newPostVC = NewPostViewController()
        newPostVC.title = "Post"
        
        let postNav = UINavigationController(rootViewController: newPostVC)
        
        let chatListVC = ChatListViewController()
        chatListVC.title = "Inbox"
        
        let chatListNav = UINavigationController(rootViewController: chatListVC)
        
        let acctVC = AccountViewController()
        acctVC.title = "Account"
        
        let acctNav = UINavigationController(rootViewController: acctVC)
        
        tabBarVC.viewControllers = [mainNav, listNav, postNav, chatListNav, acctNav]
        
        guard let items = tabBarVC.tabBar.items else { return }
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
        let tabHome = items[0]
        tabHome.title = nil
        tabHome.image = UIImage(systemName: "house")
        tabHome.selectedImage = UIImage(systemName: "house.fill")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal).withConfiguration(config)
        
        let tabList = items[1]
        tabList.title = nil
        tabList.image = UIImage(systemName: "list.dash")
        tabList.selectedImage = UIImage(systemName: "list.dash")?.withTintColor(.black, renderingMode: .alwaysOriginal).withConfiguration(config)
        
        let tabPost = items[2]
        tabPost.title = nil
        tabPost.image = UIImage(systemName: "plus")
        tabPost.selectedImage = UIImage(systemName: "plus")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal).withConfiguration(config)
        
        let tabChat = items[3]
        tabChat.title = nil
        tabChat.image = UIImage(systemName: "message")
        tabChat.selectedImage = UIImage(systemName: "message.fill")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal).withConfiguration(config)
        
        let tabAccount = items[4]
        tabAccount.title = nil
        
        if #available(iOS 14.0, *) {
            tabAccount.image = UIImage(systemName: "gearshape")
            tabAccount.selectedImage = UIImage(systemName: "gearshape.fill")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal).withConfiguration(config)
        } else {
            tabAccount.image = UIImage(systemName: "gear")
            tabAccount.selectedImage = UIImage(systemName: "gear")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal).withConfiguration(config)
        }
        
        window?.rootViewController = tabBarVC
        
        UIView.animate(withDuration: 1) { [weak self] in
            mainNav.view.alpha = 1
            self?.window?.backgroundColor = .black
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        let fileManager = FileManager.default
        let documentsUrl =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let documentsPath = documentsUrl.path
        
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentsPath)")
            print("all files in cache: \(fileNames)")
            for fileName in fileNames {
                let filePathName = "\(documentsPath)/\(fileName)"
                try fileManager.removeItem(atPath: filePathName)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
