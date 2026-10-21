cask "keyhud@beta" do
  version "1.0.1-beta.4"
  sha256 "70f1cb95adbb983273053b6325f0a40b2a738c9f4edf62a5094ba3f9457b755d"

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
