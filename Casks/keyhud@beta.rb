cask "keyhud@beta" do
  version "1.0.1-beta.1"
  sha256 "d8909326ca9c51655757b912752c01b06d87cbb6f4ecee5fd0a72c4875346cb7"

  url "https://github.com/spoutin/keyhud/releases/download/v#{version}/KeyHUD-#{version}.dmg"
  name "KeyHUD (Beta)"
  desc "Instant floating shortcut cheatsheet & hotkey HUD for macOS, Ghostty, and CLI/TUI tools (Beta stream)"
  homepage "https://github.com/spoutin/keyhud"

  auto_updates true
  conflicts_with cask: "keyhud"
  depends_on macos: ">= :sonoma"

  app "KeyHUD.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/KeyHUD.app"]
  end

  zap trash: [
    "~/.config/keyhud",
    "~/Library/Preferences/com.ablack.KeyHUD.plist",
  ]
end
