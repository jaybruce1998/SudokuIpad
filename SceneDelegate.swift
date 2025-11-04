//
//  SceneDelegate.swift
//  Sudoku
//
//  Created by Ji Won Lee on 11/3/25.
//


import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let nav = UINavigationController(rootViewController: DifficultyViewController())
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }
}
