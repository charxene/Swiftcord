//
//  ServerList.swift
//  Swiftcord
//
//  Created by Charlene Campbell on 6/4/22.
//

import Foundation
import SwiftUI
import DiscordKit

enum SelectedPage: Equatable {
	case home
	case guild(id: Snowflake)
}

struct ServerList: View {
	@EnvironmentObject var currentUserState: CurrentUserState
	@EnvironmentObject var guildStore: GuildStore
	@Binding var selectedPage: SelectedPage
	
	func guilds() -> [Guild] {
		let guilds = guildStore
			.guilds
			.values
			.filter {
				currentUserState
					.userSettings?
					.guild_positions?
					.contains($0.guild.id) ?? false
			}
			.map({ guildState in guildState.guild })
			.sorted(by: { a, b in a.joined_at! > b.joined_at! })
		
		let orderedGuilds = currentUserState
			.userSettings?
			.guild_positions?
			.compactMap({ guildId in
				guildStore.guilds[guildId]?.guild
			}) ?? []
		
		return guilds + orderedGuilds
	}
	
	var body: some View {
		ScrollView(showsIndicators: false) {
			LazyVStack(spacing: 8) {
				ServerButton(
					selected: selectedPage == .home,
					name: "Home",
					assetIconName: "DiscordIcon",
					onSelect: { selectedPage = .home }
				).padding(.top, 4)

				CustomHorizontalDivider().frame(width: 32, height: 1)

				ForEach(guilds()) { guild in
					ServerButton(
						selected: selectedPage == .guild(id: guild.id),
						name: guild.name,
						serverIconURL: guild.icon != nil ? "\(GatewayConfig.default.cdnURL)icons/\(guild.id)/\(guild.icon!).webp?size=240" : nil,
						onSelect: { selectedPage = .guild(id: guild.id) }
					)
				}

				ServerButton(
					selected: false,
					name: "Add a Server",
					systemIconName: "plus",
					bgColor: .green,
					noIndicator: true,
					onSelect: {}
				).padding(.bottom, 4)
			}
			.padding(.bottom, 8)
			.frame(width: 72)
		}
		.background(
			List {}
				.listStyle(.sidebar)
				.overlay(
					Rectangle()
						.frame(width: 1, alignment: .bottom)
						.foregroundColor(Color(nsColor: .separatorColor))
						.padding(.top, -13),
					alignment: .trailing
				)
				.overlay(.black.opacity(0.2))
		)
		.frame(maxHeight: .infinity, alignment: .top)
		.safeAreaInset(edge: .top) {
			List {}
				.listStyle(.sidebar)
				.frame(width: 72, height: 0)
				.offset(y: -13)
				.overlay(
					Rectangle()
						.frame(height: 1, alignment: .bottom)
						.foregroundColor(Color(nsColor: .separatorColor)),
					alignment: .top
				)
		}
	}
}
