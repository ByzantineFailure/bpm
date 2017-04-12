/**
 * BPM for Discord
 * (c) 2015-2017 ByzantineFailure 
 * 
 * Settings panel.  Sets up the tab in Discord settings, as well as 
 * handling switching between subpanels.  Manages teardown.
 *
 * Subpanels are inserted into `subpanelMap` and are objects of the form:
 * {
 *   init: FUNCTION(subpanel_node),
 *   teardown: FUNCTION(subpanel_node),
 *   html: RAW_HTML_STRING
 * }
 *
 * The subpanel's key in the map should be the value of `data-bpmSubpanelMessage`
 * for its tab in `base-panel.html`
 *
 * When the subpanel is selected, `html` is set as the subpanel div's innerHTML
 * and `init` is called with the subpanel div's node passed to it.
 *
 * When the settings panel is closed or another subpanel is selected, `teardown`
 * is called with the subpanel div's node passed to it.
 **/

require('!style-loader!css-loader!./settings.css');

var BPM_utils = require('../utils.js'),
    basePanelHtml = require('raw-loader!./html/base-panel.html'),
    emotes = require('./emotes.js'),
    general = require('./general.js'),
    subreddits = require('./subreddits.js'),
    search = require('./search.js'),
    updates = require('./updates.js'),
    about = require('./about.js'),
    // fragile
    INJECTION_POINT_SELECTOR = 
        '.layer > .ui-standard-sidebar-view > .content-region > .scroller-wrap > .scroller > .content-column';

//Maps subpanel requests to their corresponding init/teardown objects
var subpanelMap = {
    insert_general_settings: general,
    insert_emote_settings: emotes,
    insert_subreddit_settings: subreddits,
    insert_search_settings: search,
    insert_updates: updates,
    insert_about: about
};

// we now observe on `.app > .layers` 
// look for `.ui-standard-sidebar-view`
var settingsObserver = new MutationObserver(function(mutations) {
    // Create our settings element and insert it before the logout button w/ a separator
    function addTabElement(tabBar) {
        var tabElement = document.createElement('div');
        tabElement.className = 'ui-tab-bar-item';
        tabElement.innerHTML = 'BPM';
        tabElement.id = 'bpm-settings-tab-item';
       
        var tabSeparator = document.createElement('div');
        tabSeparator.className = 'ui-tab-bar-separator margin-top-8 margin-bottom-8';
        
        var logoutButton = document.querySelector('.ui-tab-bar-item.danger');
        var tabBar = document.querySelector('.ui-tab-bar');
        tabBar.insertBefore(tabSeparator, logoutButton);
        tabBar.insertBefore(tabElement, tabSeparator);
    }

    function addTabAndListeners(tabBar) {
        addTabElement(tabBar);
        var items = document.getElementsByClassName('ui-tab-bar-item');
        Array.prototype.forEach.call(items, function(item) {
            item.addEventListener('click', function() { 
                focusTabElement(item); 
                showSettings(item.id == 'bpm-settings-tab-item');
            }, false);
        });
    }

    mutations.forEach(function(mutation) {
        // Return if we're not adding the options layer
        if(mutation.type != 'childList' || 
           mutation.addedNodes.length === 0 || 
           !mutation.addedNodes[0].querySelector('.layer > .ui-standard-sidebar-view')) {
            return;
        }
        var addedNode = mutation.addedNodes[0];
        if(!addedNode.querySelector || !addedNode.querySelector('.layer > .ui-standard-sidebar-view')) {
            return;
        }
        BPM_utils.waitForElementByClass('ui-tab-bar SIDE', addTabAndListeners);
        BPM_utils.waitByQuerySelector(INJECTION_POINT_SELECTOR, injectSettingsPage);
    });
});

function injectSettingsPage(injectInto) {
    if(document.getElementById('bpm-settings-panel')) return;
    
    var toInject = document.createElement('div');
    toInject.id = 'bpm-settings-panel';
    toInject.style.display = 'none';
    toInject.innerHTML = basePanelHtml;

    injectInto.appendChild(toInject);
    
    addSubpanelSelectListeners();
}

//When we click done we should release all our listeners to avoid a memory leak
function addDoneClickListener(doneButton) {
    doneButton.addEventListener('click', function(e) {
        var settingElement = document.getElementById('bpm-settings-panel');
        if(settingElement) {
            settingElement.parent.removeChild(settingElement);
            //TODO: Also very ew
            var bpmTabs = BPM_utils.htmlCollectionToArray(document.getElementById('bpm-options-tab-list')
                                                .getElementsByClassName('tab-bar-item'));
            bpmTabs.forEach(function(tab) { tab.removeEventListener('click'); });
            var sidebarTabs = BPM_utils.htmlCollectionToArray(document.getElementsByClassName('tab-bar SIDE')[0]
                                                            .getElementsByClassName('tab-bar-item'));
            sidebarTabs.forEach(function(tab) { tab.removeEventListener('click'); });
            cleanSubpanel();
        }
        doneButton.removeEventListener('click', onDoneClick);
    });
}


//Initial setup for subpanels and their listeners
function addSubpanelSelectListeners() {
    var topTabs = document.getElementById('bpm-options-tab-list'),
        subpanelSelectors = BPM_utils.htmlCollectionToArray(topTabs.getElementsByTagName('div'));
    
    //TODO: WTF, ew
    var selected = subpanelSelectors.filter(function(selector) { 
        return selector.className.indexOf('selected') > -1; 
    })[0] || subpanelSelectors[0];
    
    selectSubpanel(selected, false);

    subpanelSelectors.forEach(function(selector) {
        selector.addEventListener('click', function() { selectSubpanel(selector, true); }); 
    });
}

//Clean listeners off of a subpanel
function cleanSubpanel() {
    var topTabs = document.getElementById('bpm-options-tab-list');
    var subpanelSelectors = BPM_utils.htmlCollectionToArray(topTabs.getElementsByTagName('div'));
    var selected = subpanelSelectors.filter(function(element) { return element.className.indexOf('selected') > -1; })[0];
    if(!selected) {
        console.log('BPM: called cleanSubpanel but could not find selected subpanel');
        return;
    }
    
    var content = document.getElementById('bpm-settings-subpanel');
    if(!content) {
        console.log('BPM: called cleanSubpanel without a subpanel present!');
            return;
    }

    var subpanel = getSubpanelFunctions(selected);
    subpanel.teardown(content);
}

function getSubpanelFunctions(selector) {
    return subpanelMap[selector.getAttribute('data-bpmSubpanelMessage')];
}

function selectSubpanel(selector, performTeardown) {
    var subpanelSelectors = BPM_utils.htmlCollectionToArray(selector.parentElement.getElementsByTagName('div')),
        injectTarget = document.getElementById('bpm-options-inject-target'),
        subpanel = getSubpanelFunctions(selector);

    if(performTeardown) {
        cleanSubpanel();
    }
    while(injectTarget.lastChild) {
        injectTarget.removeChild(injectTarget.lastChild);
    }

    var content = document.createElement('div');
    content.id = 'bpm-settings-subpanel';
    content.innerHTML = subpanel.html;
    injectTarget.appendChild(content);

    focusTabElement(selector, true);

    subpanel.init(content);
}

function focusTabElement(element, subpanelSelector) {
    var className = subpanelSelector ? 'tab-bar-item' : 'ui-tab-bar-item';
    var settingsItems = element.parentElement.getElementsByClassName(className);
    Array.prototype.forEach.call(settingsItems, function(item) {
        item.className = item.className.replace('selected', '');
    });
    element.className += ' selected';
}

function showSettings(display) {
    var settingsInner = document.querySelector(INJECTION_POINT_SELECTOR);
    if(!settingsInner) {
        console.log('BPM: Called showSettings when injection point does not exist!');
        return;
    }
    BPM_utils.waitForElementById('bpm-settings-panel', toggleSettingsDisplay);
    function toggleSettingsDisplay(settings) {
        if(display) {
            settingsInner.firstChild.style.display = 'none';
            settings.style.display = '';
        } else {
            settingsInner.firstChild.style.display = '';
            settings.style.display = 'none';
        } 
    }
}

BPM_utils.waitForElementById('app-mount', function(mount) {
    window.setTimeout(function(){
        var observerConfig = {
                childList: true,
                subtree: false,
                attributes: false,
                characterData: false
            }, 
            layersRoot = document.querySelector('.app > .layers');
        
        settingsObserver.observe(layersRoot, observerConfig);
    }, 100);
});

