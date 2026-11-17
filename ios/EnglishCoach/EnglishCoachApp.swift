import SwiftUI

@main
struct EnglishCoachApp: App {
    @StateObject private var articleStore = ArticleStore.shared
    @StateObject private var dictionary = DictionaryStore.shared
    @StateObject private var favorites = FavoriteStore.shared
    @StateObject private var appearance = AppearanceStore.shared
    @StateObject private var player = SpeechPlayer.shared
    @StateObject private var toast = ToastCenter.shared
    @StateObject private var backup = BackupService.shared

    @AppStorage("appTheme") private var themeRaw = ThemeMode.light.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(articleStore)
                .environmentObject(dictionary)
                .environmentObject(favorites)
                .environmentObject(appearance)
                .environmentObject(player)
                .environmentObject(toast)
                .environmentObject(backup)
                .preferredColorScheme(themeRaw == ThemeMode.dark.rawValue ? .dark : .light)
                .tint(Brand.accent)
        }
    }
}