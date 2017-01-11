// Hack to get localStorage working again.  Maybe
// Jiiks will get a better, electron-based way?
if(window.localStorage === undefined) {
    var iframe = document.createElement('iframe');
    iframe.style.display = 'none';
    document.body.appendChild(iframe);
    window.localStorage = iframe.contentWindow.localStorage;
}

// BetterDiscord pls.
window.localStorage = bdPluginStorage || window.localStorage;

require('./updates/updates.js');
require('./settings/settings.js');
require('./core/core.js');
require('./search/search.js');

