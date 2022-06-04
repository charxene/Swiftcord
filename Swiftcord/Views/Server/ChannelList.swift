//
//  ChannelList.swift
//  Swiftcord
//
//  Created by Vincent on 4/12/22.
//

import SwiftUI
import DiscordKit


enum ChannelSelection {
	case channel(id: Snowflake)
}

struct Category {
	let id: Snowflake?
	let name: String?
}

struct ChannelList: View {
	let guildId: Snowflake
	@Binding var channelSelection: ChannelSelection
	@EnvironmentObject var channelStore: ChannelStore

	private func channels() -> [Channel] {
		channelStore.channels.values.filter { channel in
			channel.guild_id == guildId
		}
	}
	
	private func categories() -> [Category] {
		[
			Category(id: nil, name: "server.channel.noCategory")
		] + channels()
			.filter({ $0.type == .category })
			.map({ Category(id: $0.id, name: $0.name) })
	}

	private func channelsForCategory(category: Category) -> [Channel] {
		channels().filter({ $0.parent_id == category.id })
	}

	var body: some View {
		List {
			ForEach(categories(), id: \.id) { category in
				let channels = channels().filter({ $0.parent_id == category.id })
				if !channels.isEmpty || category.id != nil {
					Section(header: Text(category.name ?? "").textCase(.uppercase)) {
						ForEach(channels, id: \.id) { channel in
							ChannelButton(channel: channel, selectedCh: $selCh)
								.listRowInsets(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
						}
					}
				}
			}
		}
		.padding(.top, 10)
		.listStyle(.sidebar)
		.frame(minWidth: 240, maxHeight: .infinity)
		// this overlay applies a border on the bottom edge of the view
		.overlay(Rectangle().fill(Color(nsColor: .separatorColor)).frame(width: nil, height: 1, alignment: .bottom), alignment: .top)
	}
}
