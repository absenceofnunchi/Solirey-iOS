//
//  SceneDelegate.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-04.
//

import UIKit
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        FirebaseApp.configure()
        
//        let _ = SocketDelegate()

        if let windowScene = scene as? UIWindowScene {
            self.window = UIWindow(windowScene: windowScene)
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if let user = user {
                    
                    UserDefaults.standard.set(user.uid, forKey: "userId")
                    
                    let tabBar = UITabBarController()
                    
                    let mainVC = MainViewController()
                    mainVC.title = "Main"
                    
                    let mainNav = UINavigationController(rootViewController: mainVC)
                    tabBar.addChild(mainNav)
                    
                    let acctVC = AccountViewController()
                    acctVC.title = "Account"
                    tabBar.addChild(acctVC)
                    
                    let postVC = PostViewController()
                    postVC.title = "Post"
                    
                    let postNav = UINavigationController(rootViewController: postVC)
                    tabBar.addChild(postNav)
                    
                    
                    let listVC = ListViewController()
                    listVC.title = "List"
                    
                    let listNav = UINavigationController(rootViewController: listVC)
                    tabBar.addChild(listNav)
                    
                    let walletVC = WalletViewController()
                    walletVC.title = "Wallet"
                    tabBar.addChild(walletVC)
                    
                    self.window!.rootViewController = tabBar
                } else {
                    self.window!.rootViewController = SignInViewController()
                }
                
                self.window!.makeKeyAndVisible()
            }
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

