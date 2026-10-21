cask "keyhud" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256"

  url "https://github.com/spoutin/keyhud/releases/download/v#{version}/KeyHUD-#{version}.dmg"
  name "KeyHUD"
  desc "Instant floating shortcut cheatsheet & hotkey HUD for macOS, Ghostty, and CLI/TUI tools"
  homepage "https://github.com/spoutin/keyhud"

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "KeyHUD.app"

  postflight do
    # Strip quarantine attribute automatically so Gatekeeper allows immediate launch
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/KeyHUD.app"]
  end

  zap trash: [
    "~/.config/keyhud",
    "~/Library/Preferences/com.ablack.KeyHUD.plist",
  ]
end
