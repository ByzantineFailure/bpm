/**
 * BPM for Discord Installer
 * (c) 2015-2016 ByzantineFailure
 *
 * Code to resolve the correct install paths
 **/
"use strict";
var fs = require('fs-extra'),
    path = require('path'),
    _ = require('lodash'),
    OS = process.platform;

module.exports = {
    getPaths: getPaths,
};

function getPaths(sourceRoot, isPTB, isCanary, discordRoot) {
    var discordPath = getDiscordPath(isPTB, isCanary, discordRoot);
    return {
        discordRoot: discordPath,
        discordDesktopCoreAsar: path.join(discordPath, 'discord_desktop_core', 'core.asar'),
        discordDesktopCoreBackup: path.join(discordPath,'discord_desktop_core', 'core.asar.clean'),
        discordExtract: path.join(discordPath, 'bpm_extract'),
        discordPack: path.join(discordPath, 'app.asar'),
        discordBackup: path.join(discordPath, 'app.asar.clean'),
        integrationSource: path.join(sourceRoot, 'integration.asar'),
        addonSource: path.join(sourceRoot, 'bpm.js'),
        addonDirectory: path.join(getAddonExtractPath(discordRoot), 'bpm'),
        addonTarget: path.join(getAddonExtractPath(discordRoot), 'bpm', 'bpm.js'),
        addonCustom: path.join(getAddonExtractPath(discordRoot), 'bpm', 'custom'),
        addonCustomBackup: path.join(getAddonExtractPath(discordRoot), '..', 'bpm_custom.bak')
    };
}

function modulesPathExists(path) {
    try {
        fs.statSync(path);
    } catch (err) {
        if (err.code === 'ENOENT') {
            console.log('Cannot find discord modules.  Please run discord once before installing!');
            process.exit(1);
        }
    }
}

function getAddonExtractPath(discordRoot) {
    switch(OS) {
        case 'win32':
            return path.join(process.env.APPDATA, 'discord');
        case 'darwin':
            return path.join(process.env.HOME, '/Library/Preferences/discord');
        case 'linux':
            return discordRoot;
        default:
            throw new Error('Unsupported OS ' + OS);
    }
}

function getDiscordPath(isPTB, isCanary, discordRoot) {
    var baseLocation;
    const localDataFolder = isPTB ? 'discordptb' : isCanary ? 'discordcanary' : 'discord';
    switch(OS) {
        case 'win32':
            baseLocation = path.join(process.env.APPDATA, localDataFolder);
            break;
        case 'darwin':
            baseLocation = path.join(process.env.HOME, 'Library', 'Application Support', localDataFolder);
            break;
        case 'linux':
            // slightly dangerous assumption: Discord obeys the XDG_CONFIG_HOME standard and doesn't
            // just always install itself into ~/.config regardless
            if (process.env.XDG_CONFIG_HOME) {
                baseLocation = path.join(process.env.XDG_CONFIG_HOME, localDataFolder);
            } else {
                baseLocation = path.join(process.env.HOME, '.config', localDataFolder);
            }
            break;
        default:
            throw new Error('Unsupported OS ' + OS);
    }
    modulesPathExists(baseLocation);
    const contents = fs.readdirSync(baseLocation),
        version = getLatestVersionNumber(contents, baseLocation);

    return path.join(baseLocation, version, 'modules');
}

function getLatestVersionNumber(contents, root) {
    return _(contents)
        // Only get directories
        .filter(file => fs.statSync(path.join(root, file)).isDirectory())
        // Starts with an integer or starts with "app-".  Reverse compat.
        .filter(directory => parseInt(directory.charAt(0)) || parseInt(directory.charAt(0)) === 0)
        //Sort by version number, multiple app version folders can exist
        .map(directory => {
            var splitVersion = directory.split('.');
            return {
                name: directory,
                major: parseInt(splitVersion[0]),
                minor: parseInt(splitVersion[1]),
                bugfix: parseInt(splitVersion[2])
            };
        })
        .sortBy(["major", "minor", "bugfix"])
        .last()
        .name;
}

