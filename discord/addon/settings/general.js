/**
 * Discord Integration for Typhos' Better Ponymotes
 * (c) 2015-2017 ByzantineFailure
 *
 * Handlers for the general settings subpanel
 **/

module.exports = {
    init: initGeneral,
    teardown: teardownGeneral,
    html: require('raw-loader!./html/general.html')
};

var BPM_utils = require('../utils.js');

function initGeneral(optionsPanel) {
    var inputs = BPM_utils.htmlCollectionToArray(optionsPanel.getElementsByTagName('input'));
    var checkboxes = inputs.filter(function(input) { return input.type == 'checkbox'; });

    checkboxes.forEach(function(checkbox) {
        checkbox.parentNode.addEventListener('click', function() {
            var option = checkbox.getAttribute('data-bpmoption');
            BPM_utils.setOption(option, checkbox.checked);
        });
    });
    function initPrefs(prefs) {
        checkboxes.forEach(function(checkbox) {
            checkbox.checked = prefs[checkbox.getAttribute('data-bpmoption')];  
        });
    }
    BPM_utils.retrievePrefs(initPrefs);
}

function teardownGeneral(optionsPanel) {
    var inputs = BPM_utils.htmlCollectionToArray(optionsPanel.getElementsByTagName('input'));
    var checkboxes = inputs.filter(function(input) { return input.type == 'checkbox'; });
    checkboxes.forEach(function(checkbox) {
        checkbox.nextElementSibling.removeEventListener('click');
    });
}
