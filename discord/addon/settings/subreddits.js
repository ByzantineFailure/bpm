/**
 * Discord integration for Typhos' Better Ponymotes
 * (c) 2015-2016 ByzantineFailure
 *
 * Code for initializing and tearing down the subreddits
 * settings page.
 **/

module.exports = {
    init: BPM_initSubreddits,
    teardown: BPM_teardownSubreddits,
    html: require('raw-loader!./html/subreddits.html')
};

var BPM_utils = require('../utils.js');

function BPM_initSubreddits(subpanel) {
    function initSubredditPrefs(prefs) {
        var list = document.getElementById('bpm-subreddit-list');
        Object.keys(prefs.enabledSubreddits2).forEach(function(key) {
            list.appendChild(createCheckbox(key, prefs, !!prefs.enabledSubreddits2[key]));
            
            var separator = document.createElement('div');
            separator.className = 'ui-form-divider margin-top-20 margin-bottom-20';
            list.appendChild(separator);
        });
    }
    BPM_utils.retrievePrefs(initSubredditPrefs);
}

function createCheckbox(subredditName, prefs, checked) {
    var outerDiv = document.createElement('div');
    outerDiv.className = 'ui-flex flex-horizontal flex-justify-between flex-align-center flex-nowrap margin-bottom-20';
    
    // Create the label
    var headerDiv = document.createElement('div');
    headerDiv.className = 'ui-flex flex-horizontal flex-justify-start flex-align-stretch flex-nowrap';
    headerDiv.style.flex = '0 1 auto';

    var headerText = document.createElement('h3');
    headerText.className = 'ui-form-title h3 margin-reset ui-flex-child';
    headerText.appendChild(document.createTextNode(subredditName));

    headerDiv.appendChild(headerText);
    outerDiv.appendChild(headerDiv);

    //Create the switch
    var checkboxWrapper = document.createElement('div');
    checkboxWrapper.className = 'ui-flex-child';
    checkboxWrapper.style.flex = '0 1 auto';
    
    var checkboxLabel = document.createElement('label');
    checkboxLabel.className = 'ui-switch-wrapper';

    var checkboxInput = document.createElement('input');
    checkboxInput.className = 'ui-switch-checkbox';
    checkboxInput.type = 'checkbox';
    checkboxInput.checked = checked;

    var switchDiv = document.createElement('div');
    switchDiv.className = 'ui-switch';

    checkboxWrapper.appendChild(checkboxLabel);
    checkboxLabel.appendChild(checkboxInput);
    checkboxLabel.appendChild(switchDiv);
    outerDiv.appendChild(checkboxWrapper);
    checkboxLabel.addEventListener('click', createClickHandler(subredditName, checkboxInput, prefs));

    return outerDiv;
}

function createClickHandler(subredditName, inputElement, prefs) {
    var handler = function(e) {
        //e.preventDefault();
        var newValue = inputElement.checked ? 1 : 0;
        prefs.enabledSubreddits2[subredditName] = newValue;
        BPM_utils.setOption('enabledSubreddits2', prefs.enabledSubreddits2);
    };
    return handler;
}

function BPM_teardownSubreddits(subpanel) {
    var list = document.getElementById('bpm-subreddit-list');
    var inputs = BPM_utils.htmlCollectionToArray(list.getElementsByTagName('input'));
    inputs.forEach(function(input) {
        input.parentNode.removeEventListener('click');
    });
}

