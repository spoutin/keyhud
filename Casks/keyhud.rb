cask "keyhud" do
  version "1.0.1"
  sha256 "b4722e85c7fe11f0db605ad3d10dde016b6d2cd93e38d1255aa338086af95a62"

  url "https://github.com/spoutin/keyhud/releases/download/v#{version}/KeyHUD-#{version}.dmg"
  name "KeyHUD"
  desc "Instant floating shortcut cheatsheet & hotkey HUD for macOS, Ghostty, and CLI/TUI tools"
  homepage "https://github.com/spoutin/keyhud"

  auto_updates true
  depends_on macos: :sonoma

  app "KeyHUD.app"

  zap trash: [
    "~/.config/keyhud",
    "~/Library/Preferences/com.ablack.KeyHUD.plist",
  ]
end
