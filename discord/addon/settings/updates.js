/**
 * BPM for Discord
 * (c) 2015-2017 ByzantineFailure
 * 
 * Updates panel handlers.  Version number inserted
 * during the build process (see Makefile).  Also creates
 * updates notification span and checker
 **/

module.exports = {
    init: initUpdates,
    teardown: teardownUpdates,
    html: require('raw-loader!./html/updates.html')
};

var BPM_updates = require('../updates/update-functions.js');

function initUpdates(subpanel) {
    var updateButton = document.getElementById('bpm-check-for-updates-button');
    updateButton.addEventListener('click', function(e) {
        e.preventDefault();
        BPM_updates.checkForUpdates(true);
    });
}

function teardownUpdates(subpanel) {
    var updateButton = document.getElementById('bpm-check-for-updates-button');
    updateButton.removeEventListener('click');
}

