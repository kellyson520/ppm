import UIKit
import Flutter
import LocalAuthentication

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        // Lock the vault when app goes to background
        // This is handled by the Flutter app
        super.applicationWillResignActive(application)
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        // Additional background handling
        super.applicationDidEnterBackground(application)
    }
}
