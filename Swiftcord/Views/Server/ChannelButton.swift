//
//  ChannelButton.swift
//  Swiftcord
//
//  Created by Vincent on 4/13/22.
//

import SwiftUI
import DiscordKit
import CachedAsyncImage

struct ChannelButton: View {
    let channel: Channel
    @Binding var selectedChannelId: Snowflake?

    var body: some View {
		if channel.type == .dm || channel.type == .groupDM {
			DMButton(dm: channel, selectedCh: $selectedChannelId)
				.buttonStyle(DiscordChannelButton(isSelected: selectedChannelId == channel.id))
		} else {
			GuildChButton(channel: channel, selectedCh: $selectedChannelId)
				.buttonStyle(DiscordChannelButton(isSelected: selectedChannelId == channel.id))
		}
    }
}

struct GuildChButton: View {
	let channel: Channel
	@Binding var selectedCh: Snowflake?

	@EnvironmentObject var serverCtx: ServerContext

	private let chIcons = [
		ChannelType.voice: "speaker.wave.2.fill",
		.news: "megaphone.fill"
	]

	var body: some View {
		Button { selectedCh = channel.id } label: {
			let image = (serverCtx.guild?.rules_channel_id != nil && serverCtx.guild?.rules_channel_id! == channel.id) ? "newspaper.fill" : (chIcons[channel.type] ?? "number")
			Label(channel.label() ?? "nil", systemImage: image)
				.padding(.vertical, 6)
				.padding(.horizontal, 2)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}

struct DMButton: View {
	// swiftlint:disable identifier_name
	let dm: Channel
	@Binding var selectedCh: Snowflake?
	@EnvironmentObject var userStore: UserStore


	var body: some View {
		Button { selectedCh = dm.id } label: {
			HStack {
				if dm.type == .dm,
				   let userId = dm.recipient_ids?.first,
				   let user = userStore.users[userId] {
					CachedAsyncImage(url: user.user.avatarURL(size: 64)) { image in
						image.resizable().scaledToFill()
					} placeholder: { Rectangle().fill(.gray.opacity(0.2)) }
					.frame(width: 32, height: 32)
					.clipShape(Circle())
				} else {
					Image(systemName: "person.2.fill")
						.foregroundColor(.white)
						.frame(width: 32, height: 32)
						.background(.red)
						.clipShape(Circle())
				}

				VStack(alignment: .leading, spacing: 2) {
					Text(dm.label(userStore.users.mapValues({ $0.user })) ?? "nil")
					if dm.type == .groupDM {
						Text("\((dm.recipient_ids?.count ?? 2) + 1) Members").font(.caption)
					}
				}
				Spacer()
			}
			.padding(.horizontal, 6)
			.padding(.vertical, 5)
		}
	}
}

struct DiscordChannelButton: ButtonStyle {
	let isSelected: Bool
	@State var isHovered: Bool = false

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.buttonStyle(.borderless)
			.font(.system(size: 14, weight: isSelected ? .medium : .regular))
			.foregroundColor(isSelected ? Color(nsColor: .labelColor) : .gray)
			.accentColor(isSelected ? Color(nsColor: .labelColor) : .gray)
			.background(
				RoundedRectangle(cornerRadius: 4)
					.fill(isSelected ? .gray.opacity(0.3) : (isHovered ? .gray.opacity(0.2) : .clear))
            )
            .onHover(perform: { isHovered = $0 })
    }
}
