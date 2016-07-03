# BPM for BetterDiscord Plugin

BPM for Discord does not reliably co-exist with [the BetterDiscord project](https://github.com/Jiiks/BetterDiscordApp)

To support this use case, I have created a version of BPM which works as a BetterDiscord plugin.

**The plugin is not be guaranteed to be reliable, and I am not actively monitoring it for issues.  If you have an issue I encourage you to file an issue on [the repo issues page](https://github.com/ByzantineFailure/BPM-for-Discord/issues) to make me aware of it.**

The Custom JS feature does not work with the BetterDiscord plugin version.  You will have to port any custom scripts you have written for BPM for Discord into BetterDiscord plugins if you would like them to work.

## Installation

Ensure you have BetterDiscord installed and it is working properly.

Download `betterDiscord-bpm.plugin.js`.

Move the `betterDiscord-bpm.plugin.js` file into BetterDiscord's plugin directory.
* Windows: `%APPDATA%/BetterDiscord/plugins`
* Mac: `~/Library/Preferences/BetterDiscord/plugins`
* Linux: `~/.config/BetterDiscord/plugins`

Restart Discord after doing this and you should be in business.

## If you have previously installed Non-BetterDiscord BPM

Reinstall Discord before installing BetterDiscord.  Failing to do this results in unknown, almost-always broken behavior.

Install BetterDiscord, then follow the instructions above.
