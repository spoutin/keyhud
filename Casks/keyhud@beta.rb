cask "keyhud@beta" do
  version "1.0.1-beta.15"
  sha256 "8db9592cac03413b401bda3afbaf3f1e9ea95cf4fcb662cbe895a635c2b19e00"

  url "https://github.com/spoutin/keyhud/releases/download/v#{version}/KeyHUD-#{version}.dmg"
  name "KeyHUD (Beta)"
  desc "Instant floating shortcut cheatsheet & hotkey HUD for macOS, Ghostty, and CLI/TUI tools (Beta stream)"
  homepage "https://github.com/spoutin/keyhud"

  auto_updates true
  conflicts_with cask: "keyhud"
  depends_on macos: :sonoma

  app "KeyHUD.app"

  zap trash: [
    "~/.config/keyhud",
    "~/Library/Preferences/com.ablack.KeyHUD.plist",
  ]
end
