//
//  AppDelegate.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-04.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore
import UserNotifications
import Combine
import web3swift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"
    var storage = Set<AnyCancellable>()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.min)

        Messaging.messaging().delegate = self
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()

        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
//                print("FCM registration token: \(token)")
                let user = Auth.auth().currentUser
                if let user = user {
                    let uid = user.uid
                    FirebaseService.shared.db.collection("deviceToken").document(uid).setData(["token": FieldValue.arrayUnion([token])], merge: true)
                }
            }
        }
        // chat message
        // status update
        // subscription
        // https://firebase.google.com/docs/cloud-messaging/ios/topic-messaging#manage_topic_subscriptions_from_the_server
        
        if let options = launchOptions, let notification = options[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
            print("notification", notification)
            self.application(application, didReceiveRemoteNotification: notification)
        }
        
        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable : Any] {
            // Handle your app navigation accordingly and update the webservice as per information on the app.
            print("remoteNotification", remoteNotification)
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("didReceiveRemoteNotification1 Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("didReceiveRemoteNotification2 Message ID: \(messageID)")
        }
        
        // Print full message.
        print("Print full message.", userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate, PostParseDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // [START_EXCLUDE]
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("willPresent Message ID: \(messageID)")
        }
        // [END_EXCLUDE]
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([[.alert, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // [START_EXCLUDE]
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("didReceive Message ID: \(messageID)")
        }
        // [END_EXCLUDE]
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print full message.
        print("userInfo", userInfo)
        

        // getting access to the window object from SceneDelegate
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate
        else {
            completionHandler()
            return
        }
        
        if let rootViewController = sceneDelegate.window?.rootViewController {
            guard let messageType = userInfo["messageType"] as? String else {
                completionHandler()
                return
            }
            
            switch messageType {
                case "chat":
                    // docId, sellerUserId, buyerUserId
                    // the sellerUserId/buyerUserId names are misnomers and have to be changed
                    // they simply have to be two members of a chat room
                    // going with how the chat room currently has sellerUserId/buyerUserId labels for now
                    // ChatVC will compare them against UserId to determine whether to display the message on the right side or the left side
                    if let docId = userInfo["docId"] as? String,
                       let sellerUserId = userInfo["uid"] as? String,
                       let buyerUserId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId),
                       let displayName = userInfo[UserDefaultKeys.displayName] as? String,
                       let address = userInfo[UserDefaultKeys.address] as? String {
                        
                        let chatModelCore = PostCoreModel(documentId: docId, buyerUserId: buyerUserId, sellerUserId: sellerUserId)
                        let shippingAddress = ShippingAddress(address: address)
                        
                        let userInfo = UserInfo(
                            email: nil,
                            displayName: displayName,
                            photoURL: nil,
                            uid: nil,
                            memberSince: nil,
                            shippingAddress: shippingAddress
                        )
                        
                        if let tabBarController = rootViewController as? UITabBarController,
                           let navController = tabBarController.selectedViewController as? UINavigationController {
                            
                            let chatVC = ChatViewController()
                            chatVC.post = chatModelCore
                            chatVC.userInfo = userInfo
                            navController.pushViewController(chatVC, animated: true)
                        }
                    }
                case "status":
                    // for updating the status of the online direct purchases using escrow
                    guard let docId = userInfo["docID"] as? String else {
                        completionHandler()
                        return
                    }
                    
                    let docRef = FirebaseService.shared.db.collection("post").document(docId)
                    docRef.getDocument { [weak self] (document, error) in
                        if let error = error {
                            print("app delegate error", error)
                            completionHandler()
                            return
                        }
                        
                        guard let document = document,
                              let post = self?.parseDocument(document: document),
                              let status = PostStatus(rawValue: post.status),
                              let tabBarController = rootViewController as? UITabBarController,
                              let navController = tabBarController.selectedViewController as? UINavigationController,
                              let userId = UserDefaults.standard.string(forKey: UserDefaultKeys.userId) else {
                            completionHandler()
                            return
                        }
                        
                        switch status {
                            case .pending:
                                /// buyer to seller
                                guard userId == post.sellerUserId else {
                                    completionHandler()
                                    return
                                }
                                break
                            case .transferred:
                                /// seller to buyer
                                guard userId == post.buyerUserId else {
                                    completionHandler()
                                    return
                                }
                                break
                            case .complete:
                                guard userId == post.sellerUserId else {
                                    completionHandler()
                                    return
                                }
                                break
                            default:
                                break
                        }
                        
                        let listDetailVC = ListDetailViewController()
                        listDetailVC.post = post
                        navController.pushViewController(listDetailVC, animated: true)
                        //                                      let viewControllers = tabBarController.viewControllers else { return }
                        //                                for case let navController as UINavigationController in viewControllers where navController.title == "List" {
                        //                                    if let listVC = navController.viewControllers.first as? ListViewController {
                        //                                        listVC.segmentedControl.selectedSegmentIndex = 1
                        //                                        listVC.segmentedControl.sendActions(for: UIControl.Event.valueChanged)
                        //
                        //                                    }
                        //                                }
                    }
                case "topic":
                    // for updating the status of the online direct purchases using escrow
                    guard let docId = userInfo["docId"] as? String else {
                        completionHandler()
                        return
                    }
                                        
                    let docRef = FirebaseService.shared.db.collection("post").document(docId)
                    docRef.getDocument { [weak self] (document, error) in
                        if let error = error {
                            print("app delegate error", error)
                            completionHandler()
                            return
                        }
                        
                        guard let document = document,
                              let post = self?.parseDocument(document: document),
                              let tabBarController = rootViewController as? UITabBarController,
                              let navController = tabBarController.selectedViewController as? UINavigationController,
                              let auctionHash = post.auctionHash,
                              let self = self else {
                            completionHandler()
                            return
                        }
                        
                        Future<TransactionReceipt, PostingError> { promise in
                            Web3swiftService.getReceipt(hash: auctionHash, promise: promise)
                        }
                        .sink { (completion) in
                            print("completion", completion)
                        } receiveValue: { (receipt) in
                            guard let contractAddress = receipt.contractAddress,
                                  let currentAddress = Web3swiftService.currentAddress else { return }
                            let auctionDetailVC = AuctionDetailViewController(auctionContractAddress: contractAddress, myContractAddress: currentAddress)
                            auctionDetailVC.post = post
                            navController.pushViewController(auctionDetailVC, animated: true)
                        }
                        .store(in: &self.storage)
                    }
                default:
                    break
            }
        }
        
        completionHandler()
    }
}
// [END ios_10_message_handling]

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        print("Firebase registration token: \(String(describing: fcmToken))")
        if let fcmToken = fcmToken {
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if let user = user {
                    FirebaseService.shared.db.collection("deviceToken").document(user.uid).updateData(["token": FieldValue.arrayUnion([fcmToken])])
                }
            }
            
            UserDefaults.standard.set(fcmToken, forKey: UserDefaultKeys.fcmToken)
        }
//        let dataDict:[String: String] = ["token": fcmToken ?? ""]
//        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    // [END refresh_token]
}
