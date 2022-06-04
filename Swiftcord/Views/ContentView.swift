//
//  ContentView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 19/2/22.
//

import SwiftUI
import CoreData
import os
import DiscordKit
import DiscordKitCommon

struct CustomHorizontalDivider: View {
    var body: some View {
        Rectangle().fill(Color(NSColor.separatorColor))
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    /*@FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MessageItem.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<MessageItem>*/

    @State private var sheetOpen = false
	@State private var selectedPage: SelectedPage = .home

    @StateObject var loginWVModel: WebViewModel = WebViewModel(link: "https://canary.discord.com/login")
    @StateObject private var audioManager = AudioCenterManager()

    @EnvironmentObject var gateway: DiscordGateway
    @EnvironmentObject var state: UIState
	@EnvironmentObject var guildStore: GuildStore

    private let log = Logger(category: "ContentView")

	private func loadLastSelectedGuild() {
		if let guildId = UserDefaults.standard.string(forKey: "lastSelectedGuild"),
		   guildStore.guilds[guildId] != nil {
			selectedPage = .guild(id: guildId)
		}
	}

    var body: some View {
        HStack(spacing: 0) {
            ServerList(selectedPage: $selectedPage)
			switch selectedPage {
			case .home:
				Text("Home Page")
			case .guild(let id):
				if let guild = guildStore.guilds[id] {
					ServerView(
						guildState: guild
					)
				} else {
					Text("Guild isn't loaded :(")
				}
			}
        }
        .environmentObject(audioManager)
        .onChange(of: state.loadingState, perform: { state in
			if state == .gatewayConn { loadLastSelectedGuild() }
        })
        // Using .constant to prevent dismissing
        .sheet(isPresented: .constant(state.attemptLogin)) {
            ZStack(alignment: .topLeading) {
                WebView()
                    .environmentObject(loginWVModel)
                    .frame(width: 831, height: 580)
                Button("Quit", role: .cancel) { exit(0) }.padding(8)

                if !loginWVModel.didFinishLoading {
                    ZStack {
                        ProgressView("Loading Discord login...")
                            .controlSize(.large)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .background(.background)
                }
            }
        }
        .onChange(of: loginWVModel.token, perform: { token in
            if let token = token {
                state.attemptLogin = false
                Keychain.save(key: "authToken", data: token)
                gateway.connect() // Reconnect to the socket
            }
        })
        .onAppear {
			if state.loadingState == .messageLoad { loadLastSelectedGuild() }

            _ = gateway.onAuthFailure.addHandler {
                state.attemptLogin = true
                state.loadingState = .initial
                log.debug("User isn't logged in, attempting login")
            }
            _ = gateway.onEvent.addHandler { (evt, _) in
                switch evt {
                case .ready:
                    state.loadingState = .gatewayConn
                    fallthrough
                case .resumed:
                    gateway.socket.send(op: .voiceStateUpdate, data: GatewayVoiceStateUpdate(
                        guild_id: nil,
                        channel_id: nil,
                        self_mute: state.selfMute,
                        self_deaf: state.selfDeaf,
                        self_video: false
                    ))
                default: break
                }
            }
            _ = gateway.socket.onSessionInvalid.addHandler { state.loadingState = .initial }
        }
	}

    /*private func addItem() {
        withAnimation {
            let newItem = MessageItem(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
	 You should not use this function in a shipping application, although it may be useful
	 during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
	 You should not use this function in a shipping application, although it may be useful
	 during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }*/
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
