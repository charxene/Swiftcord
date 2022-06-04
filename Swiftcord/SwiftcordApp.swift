//
//  Native_DiscordApp.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 19/2/22.
//

import DiscordKit
import SwiftUI

@main
struct SwiftcordApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	let persistenceController = PersistenceController.shared
	@StateObject var updaterViewModel = UpdaterViewModel()

	@StateObject private var gateway = DiscordGateway()
	@StateObject private var state = UIState()

	var body: some Scene {
		WindowGroup {
			ContentView()
				.preferredColorScheme(gateway.store.currentUserState.userSettings?.theme == UITheme.light ? .light : .dark)
				.overlay(LoadingView())
				.environmentObject(gateway.store.channelStore)
				.environmentObject(gateway.store.userStore)
				.environmentObject(gateway.store.guildStore)
				.environmentObject(gateway.store.currentUserState)
				.environmentObject(state)
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
		}
		.commands {
			CommandGroup(after: .appInfo) {
				CheckForUpdatesView(updaterViewModel: updaterViewModel)
			}

			SidebarCommands()
			NavigationCommands()
		}

		Settings {
			SettingsView()
				.preferredColorScheme(gateway.store.currentUserState.userSettings?.theme == UITheme.light ? .light : .dark)
				.environmentObject(gateway)
				.environmentObject(state)
				// .environment(\.locale, .init(identifier: "zh-Hans"))
		}
	}
}
