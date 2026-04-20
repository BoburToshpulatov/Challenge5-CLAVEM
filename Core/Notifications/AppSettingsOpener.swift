//
//  AppSettingsOpener.swift
//  The Lord of Land
//
//  Created by Bobur Toshpulatov on 10/03/26.
//


import UIKit

enum AppSettingsOpener {
    static func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}