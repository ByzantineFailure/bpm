/**
 * Discord Integration for Typhos' BetterPonymotes
 * (c) 2015 ByzantineFailure
 *
 * Utility functions
 **/
module.exports = {
    htmlCollectionToArray: htmlCollectionToArray,
    getElementsByClassName: getElementsByClassName,
    setOption: setOption,
    retrievePrefs: retrievePrefs,
    waitForElementById: waitForElementById,
    waitForElementByClass: waitForElementByClass,
    waitByQuerySelector: waitByQuerySelector
};

function waitForElementByClass(elementClass, callback) {
    var element = document.getElementsByClassName(elementClass);
    if(element.length == 0) {
        window.setTimeout(function() { waitForElementByClass(elementClass, callback); }, 100);
    } else {
        callback(element[0]);
    }
}

function waitForElementById(id, callback) {
    var element = document.getElementById(id);
    if(!element) {
        window.setTimeout(function() { waitForElementById(id, callback); }, 100);
    } else {
        callback(element);
    }
}

function waitByQuerySelector(selector, callback) {
    var element = document.querySelector(selector);
    if(!element) {
        window.setTimeout(function() { waitForElementById(selector, callback); }, 100);
    } else {
        callback(element);
    }
}

function getElementsByClassName(className) {
    var elements = document.getElementsByClassName(className);
    return htmlCollectionToArray(elements);
}

function htmlCollectionToArray(coll) {
    return [].slice.call(coll);
}

function setOption(option, value) {
    var bpmEvent = new CustomEvent('bpm_message')
    bpmEvent.data = { method: 'set_pref', pref: option, value: value };
    window.dispatchEvent(bpmEvent);
}

function retrievePrefs(callback) {
    var prefsListener = function(e) {
        var message = e.data;
        switch(message.method) {
            case 'prefs':
                window.removeEventListener('bpm_message', prefsListener);
                callback(message.prefs);
                break;
        }
    }
    window.addEventListener('bpm_message', prefsListener, false);
    var getPrefs = new CustomEvent('bpm_message');
    getPrefs.data = { method: 'get_prefs' };
    window.dispatchEvent(getPrefs);
}

