/**
 * BPM for Discord
 * (c) 2015-2016 ByzantineFailure
 *
 * Core BPM code.  This code's requires rely on a lot of Makefile magic.
 * The dependencies are built by the BPM core build process then moved here 
 * before the webpack occurs.
 **/

var utils = require('../utils');

var cssMap = {};
cssMap['/emote-classes.css'] = require('raw-loader!./emote-classes.css');
cssMap['/gif-animotes.css'] = require('raw-loader!./gif-animotes.css');
cssMap['/bootstrap.css'] = require('raw-loader!./bootstrap.css');
cssMap['/bpmotes.css'] = require('raw-loader!./bpmotes.css');
cssMap['/combiners-nsfw.css'] = require('raw-loader!./combiners-nsfw.css');
cssMap['/extracss-pure.css'] = require('raw-loader!./extracss-pure.css');
cssMap['/extracss-webkit.css'] = require('raw-loader!./extracss-webkit.css');

function getChatInputTextarea() {
    var sendbox = utils.getElementsByClassName('channel-text-area-default');
    if(sendbox.length === 0) {
        return null;
    }
    return utils.htmlCollectionToArray(sendbox[0].getElementsByTagName('textarea'))[0];
}

window.addEventListener('bpm_backend_message', function(event) {
    var message = event.data;
    switch(message.method) {
        case 'insert_css':
            var css = cssMap[message.file];
            var node = document.createElement('style');
            node.type = 'text/css';
            node.appendChild(document.createTextNode(css));
            document.head.appendChild(node);    
            break;
        //We may consider perhaps making this an option instead.
        case 'insert_emote':
            var chatbox = getChatInputTextarea();
            if(!chatbox) {
                console.log('Cannot add search emote "' + message.emote + '", chat textarea does not exist');
                return;
            }
            chatbox.value = chatbox.value + "[](" + message.emote + ")";
            break;
        default:
            console.log('BPM: unrecognized discord message: ' + message.method);
            break;
    }
});

//Require BPM content in last
require('./bpm-resources.js');
require('./pref-setup.js');
require('./background.js');
require('./betterponymotes.js');

