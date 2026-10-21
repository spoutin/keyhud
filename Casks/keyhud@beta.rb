cask "keyhud@beta" do
  version "1.0.1-beta.10"
  sha256 "b0eec1b25f2e20839581428c33cb2aa8efe80af833231d959bc7410cd9e9c2e5"

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
