import UIKit
import Flutter
import firebase_core
import firebase_messaging
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Initialize Firebase
        FirebaseApp.configure()

        // Register plugins
        GeneratedPluginRegistrant.register(with: self)

        // ===== Notification setup =====
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { granted, error in
                    if let error = error {
                        print("❌ Notification permission error: \(error)")
                    } else {
                        print("✅ Notification permission granted: \(granted)")
                    }
                }
            )
        }

        application.registerForRemoteNotifications()

        // Set Messaging delegate
        Messaging.messaging().delegate = self

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ===== FCM token received =====
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ FCM token: \(fcmToken ?? "none")")
        // Here you can send the token to your backend if needed
    }

    // ===== Receive foreground notification (iOS 10+) =====
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

    // ===== Handle notification tap =====
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification tap here if needed
        completionHandler()
    }
}








// import Flutter
// import UIKit
//
// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }
