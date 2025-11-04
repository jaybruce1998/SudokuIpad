import UIKit

@main
class SudokuApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // Create the window
        let window = UIWindow(frame: UIScreen.main.bounds)
        let nav = UINavigationController(rootViewController: DifficultyViewController())
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window

        return true
    }
}
