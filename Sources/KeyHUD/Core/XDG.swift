import Foundation

// MARK: - XDG Base Directory Support

struct XDG {
    static var homeDirectory: String {
        FileManager.default.homeDirectoryForCurrentUser.path
    }

    /// $XDG_CONFIG_HOME, defaulting to ~/.config
    static var configHome: String {
        if let env = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"], !env.trimmingCharacters(in: .whitespaces).isEmpty {
            return (env as NSString).expandingTildeInPath
        }
        return "\(homeDirectory)/.config"
    }

    /// $XDG_DATA_HOME, defaulting to ~/.local/share
    static var dataHome: String {
        if let env = ProcessInfo.processInfo.environment["XDG_DATA_HOME"], !env.trimmingCharacters(in: .whitespaces).isEmpty {
            return (env as NSString).expandingTildeInPath
        }
        return "\(homeDirectory)/.local/share"
    }

    /// $XDG_STATE_HOME, defaulting to ~/.local/state
    static var stateHome: String {
        if let env = ProcessInfo.processInfo.environment["XDG_STATE_HOME"], !env.trimmingCharacters(in: .whitespaces).isEmpty {
            return (env as NSString).expandingTildeInPath
        }
        return "\(homeDirectory)/.local/state"
    }

    /// $XDG_CACHE_HOME, defaulting to ~/.cache
    static var cacheHome: String {
        if let env = ProcessInfo.processInfo.environment["XDG_CACHE_HOME"], !env.trimmingCharacters(in: .whitespaces).isEmpty {
            return (env as NSString).expandingTildeInPath
        }
        return "\(homeDirectory)/.cache"
    }

    // KeyHUD Specific Locations
    static var keyhudConfigDir: String { "\(configHome)/keyhud" }
    static var keyhudConfigFile: String { "\(keyhudConfigDir)/custom_shortcuts.json" }
    static var keyhudDataDir: String { "\(dataHome)/keyhud" }
    static var keyhudStateDir: String { "\(stateHome)/keyhud" }

    // External Discovered Tool Configs
    static var aerospaceConfigPath: String {
        let xdgPath = "\(configHome)/aerospace/aerospace.toml"
        if FileManager.default.fileExists(atPath: xdgPath) {
            return xdgPath
        }
        let legacyPath = "\(homeDirectory)/.aerospace.toml"
        if FileManager.default.fileExists(atPath: legacyPath) {
            return legacyPath
        }
        return xdgPath
    }

    static var herdrConfigPath: String { "\(configHome)/herdr/config.toml" }
    static var nvimKeymapsPath: String { "\(configHome)/nvim/lua/config/keymaps.lua" }
    static var k9sConfigDir: String { "\(configHome)/k9s" }
    static var lazygitConfigDir: String { "\(configHome)/lazygit" }
    static var atuinConfigDir: String { "\(configHome)/atuin" }
}
