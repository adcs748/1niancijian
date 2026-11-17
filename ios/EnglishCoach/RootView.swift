import SwiftUI
import PhotosUI
import Foundation

struct SkinKeyWrapper: Identifiable {
    let key: String
    var id: String { key }
}

struct RootView: View {
    @EnvironmentObject private var appearance: AppearanceStore
    @EnvironmentObject private var player: SpeechPlayer

    @State private var showLaunch = false
    @State private var launchData: Data?
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            NavigationStack {
                HomeView()
            }
            .background(Brand.pageBackground.ignoresSafeArea())

            if player.isActive {
                VStack {
                    Spacer()
                    PlayerBar()
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }

            if appearance.isEditing {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap")
                        Text("点击组件更换底层图案")
                        Spacer()
                        Button("完成") {
                            appearance.endSkinEditing()
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Brand.accent))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    Spacer()
                }
            }

            if showLaunch {
                LaunchOverlayView(data: launchData, config: appearance.config.launch)
                    .transition(.opacity)
            }

            ToastOverlay()
        }
        .sheet(item: skinSheetBinding, onDismiss: {
            appearance.dismissSkinEditor()
        }) { wrapper in
            SkinEditorSheet(key: wrapper.key)
                .environmentObject(appearance)
                .presentationDetents([.height(380), .medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if appearance.config.launch.enabled {
                triggerLaunch()
            }
        }
        .onChange(of: appearance.launchPreviewToken) { _, _ in
            triggerLaunch()
        }
        .onChange(of: appearance.config.launch.enabled) { _, enabled in
            if !enabled {
                hideTask?.cancel()
                showLaunch = false
                launchData = nil
            }
        }
    }

    private var skinSheetBinding: Binding<SkinKeyWrapper?> {
        Binding(
            get: {
                guard let key = appearance.editingSkinKey else { return nil }
                return SkinKeyWrapper(key: key)
            },
            set: { value in
                if value == nil {
                    appearance.dismissSkinEditor()
                }
            }
        )
    }

    private func triggerLaunch() {
        hideTask?.cancel()
        launchData = appearance.launchImageData

        withAnimation(.easeInOut(duration: 0.2)) {
            showLaunch = true
        }

        let duration = max(0.5, appearance.config.launch.duration)
        hideTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                showLaunch = false
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            launchData = nil
        }
    }
}

struct LaunchOverlayView: View {
    let data: Data?
    let config: LaunchConfig

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Brand.pageBackground

                if let data = data {
                    if config.originalType.contains("gif") {
                        GIFImageView(data: data, contentMode: config.fit == "cover" ? .scaleAspectFill : .scaleAspectFit)
                            .frame(
                                width: mediaWidth(proxy),
                                height: config.fit == "cover" ? proxy.size.height : proxy.size.height * 0.7
                            )
                            .clipped()
                    } else if let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: config.fit == "cover" ? .fill : .fit)
                            .frame(
                                maxWidth: config.fit == "cover" ? .infinity : proxy.size.width * config.size / 100,
                                maxHeight: config.fit == "cover" ? .infinity : proxy.size.height * 0.7
                            )
                            .clipped()
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("EnglishCoach")
                            .font(.system(size: 24, weight: .heavy))
                        Text("四六级英语")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }

    private func mediaWidth(_ proxy: GeometryProxy) -> CGFloat? {
        guard config.fit != "cover" else { return proxy.size.width }
        return proxy.size.width * config.size / 100
    }
}

struct PlayerBar: View {
    @EnvironmentObject private var player: SpeechPlayer

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(player.label.isEmpty ? "正在播放" : player.label)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                if player.isPaused {
                    player.resume()
                } else {
                    player.pause()
                }
            } label: {
                Image(systemName: player.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)

            Button {
                player.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.12), radius: 12, y: 6)
        )
    }

    private var subtitle: String {
        var parts: [String] = []
        parts.append("\(min(player.index + 1, max(player.total, 1)))/\(player.total)")
        parts.append(player.loop ? "循环" : "单次")
        if player.remainingSeconds > 0 {
            let minutes = player.remainingSeconds / 60
            let seconds = player.remainingSeconds % 60
            parts.append(String(format: "%d:%02d 后停止", minutes, seconds))
        }
        return parts.joined(separator: " · ")
    }
}

struct SkinEditorSheet: View {
    @EnvironmentObject private var appearance: AppearanceStore
    @Environment(\.dismiss) private var dismiss

    let key: String

    @State private var pickerItem: PhotosPickerItem?
    @State private var opacity: Double = 0.35
    @State private var brightness: Double = 1.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("组件图案")
                        .font(.system(size: 18, weight: .bold))
                    Text(key)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    preview

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("从相册选择", systemImage: "photo.on.rectangle")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.accent.opacity(0.12)))
                            .foregroundStyle(Brand.accent)
                    }

                    HStack(spacing: 10) {
                        Text("图案透明度")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Slider(value: $opacity, in: 0...1)
                        Text("\(Int(opacity * 100))%")
                            .font(.system(size: 12))
                            .frame(width: 40, alignment: .trailing)
                    }

                    HStack(spacing: 10) {
                        Text("图案深浅")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Slider(value: $brightness, in: 0.2...1.8)
                        Text("\(Int(brightness * 100))%")
                            .font(.system(size: 12))
                            .frame(width: 40, alignment: .trailing)
                    }

                    Button {
                        appearance.clearSkin(key: key)
                    } label: {
                        Text("清除图案")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.red.opacity(0.1)))
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 10)
                }
                .padding(20)
            }
            .background(Brand.pageBackground.ignoresSafeArea())
            .navigationTitle("外观编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        appearance.dismissSkinEditor()
                        dismiss()
                    }
                }
            }
            .onAppear {
                opacity = appearance.skinOpacity(key)
                brightness = appearance.skinBrightness(key)
            }
            .onChange(of: opacity) { _, newValue in
                appearance.setSkinOpacity(key: key, value: newValue)
            }
            .onChange(of: brightness) { _, newValue in
                appearance.setSkinBrightness(key: key, value: newValue)
            }
            .onChange(of: pickerItem) { _, item in
                loadImage(item)
            }

        }
    }

    @ViewBuilder
    private var preview: some View {
        if let image = appearance.skinImage(key) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 120)
                .overlay {
                    Text("暂无图案")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
        }
    }

    @MainActor
    private func loadImage(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                appearance.updateSkin(key: key, data: data)
            }
        }
    }
}