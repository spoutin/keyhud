cask "keyhud" do
  version "1.0.0"
  sha256 "1153d4d6e2574443cc5b98bb992e9f893abe592e22fb2aee7e438606856e3577"

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
