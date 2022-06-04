//
//  ServerView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 23/2/22.
//

import SwiftUI
import DiscordKit

class ServerContext: ObservableObject {
    @Published public var channel: Channel?
    @Published public var guild: Guild?
    @Published public var typingStarted: [Snowflake: [TypingStart]] = [:]
	@Published public var roles: [Role] = []
}

struct ServerView: View {
	@ObservedObject var guildState: GuildState
    @State private var evtID: EventDispatch.HandlerIdentifier?
    @State private var mediaCenterOpen: Bool = false
	@State private var selectedChannelId: Snowflake?
	
	@EnvironmentObject var channelStore: ChannelStore
    @EnvironmentObject var state: UIState
    @EnvironmentObject var gateway: DiscordGateway
    @EnvironmentObject var audioManager: AudioCenterManager

    @StateObject private var serverCtx = ServerContext()

    private func toggleSidebar() {
        #if os(macOS)
		NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        #endif
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
				ChannelList(guildId: guildState.guild.id, channelSelection: $selectedChannelId)
					.toolbar {
						ToolbarItem {
							Text(guildState.guild.name == "DMs" ? "dm" : "\(guildState.guild.name)")
								.font(.title3)
								.fontWeight(.semibold)
								.frame(maxWidth: 208) // Largest width before disappearing
						}
					}
					.onChange(of: $selectedChannelId) { newID in
						guard let newID = newID else { return }
						UserDefaults.standard.setValue(
							newID,
							forKey: "lastCh.\(serverCtx.guild!.id)"
						)
					}

                if !gateway.connected || !gateway.reachable {
					Label(gateway.reachable
						  ? "Reconnecting..."
						  : "No network connectivity",
						  systemImage: gateway.reachable ? "arrow.clockwise" : "bolt.horizontal.fill")
						.frame(maxWidth: .infinity)
						.padding(.vertical, 4)
						.background(gateway.reachable ? .orange : .red)
                }
				CurrentUserFooter(user: user)
            }

			if serverCtx.channel != nil {
				MessagesView().equatable()
			} else {
				VStack(spacing: 24) {
					Image(serverCtx.guild?.id == "@me" ? "NoDMs" : "NoGuildChannels")
					if serverCtx.guild?.id == "@me" {
						Text("dm.noChannels.body").opacity(0.75)
					} else {
						Text("server.noChannels.header").font(.headline).textCase(.uppercase)
						Text("server.noChannels.body")
							.padding(.top, -16)
							.multilineTextAlignment(.center)
					}
				}
				.padding()
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.background(.gray.opacity(0.15))
			}
        }
		.environmentObject(serverCtx)
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                HStack {
					Image(
						systemName: serverCtx.channel?.type == .dm ? "at" :
							(serverCtx.channel?.type == .groupDM ? "person.2.fill" : "number")
					).font(.system(size: 18)).opacity(0.77).frame(width: 24, height: 24)
					Text(serverCtx.channel?.label(gateway.cache.users) ?? "No Channel")
						.font(.title2)
                }
            }
            ToolbarItem(placement: .navigation) {
                Button(action: { mediaCenterOpen = true }, label: { Image(systemName: "play.circle") })
                    .popover(isPresented: $mediaCenterOpen) { MediaControllerView() }
            }
        }
        .onChange(of: audioManager.queue.count) { [oldCount = audioManager.queue.count] count in
            if count > oldCount { mediaCenterOpen = true }
        }
        .onChange(of: state.loadingState) { newState in if newState == .gatewayConn { loadChannels() }}
        .onAppear {
			if let guild = guild { bootstrapGuild(with: guild) }

			// swiftlint:disable identifier_name
            evtID = gateway.onEvent.addHandler { (evt, d) in
                switch evt {
                /*case .channelUpdate:
                    guard let updatedCh = d as? Channel else { break }
                    if let chPos = channels.firstIndex(where: { ch in ch == updatedCh }) {
                        // Crappy workaround for channel list to update
                        var chs = channels
                        chs[chPos] = updatedCh
                        channels = []
                        channels = chs
                    }
                    // For some reason, updating one element doesnt update the UI
                    // loadChannels()*/
                case .typingStart:
                    guard let typingData = d as? TypingStart,
                          typingData.user_id != gateway.cache.user!.id
                    else { break }

					// Remove existing typing items, if present (prevent duplicates)
					serverCtx.typingStarted[typingData.channel_id]?.removeAll {
						$0.user_id == typingData.user_id
					}

                    if serverCtx.typingStarted[typingData.channel_id] == nil {
                        serverCtx.typingStarted[typingData.channel_id] = []
                    }
                    serverCtx.typingStarted[typingData.channel_id]!.append(typingData)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
                        serverCtx.typingStarted[typingData.channel_id]?.removeAll {
                            $0.user_id == typingData.user_id
                            && $0.timestamp == typingData.timestamp
                        }
                    }
                default: break
                }
            }
        }
        .onDisappear {
            if let evtID = evtID { _ = gateway.onEvent.removeHandler(handler: evtID) }
        }
    }
}
