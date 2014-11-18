var jqueryPubSub = require('./modules/moj.jquery-pub-sub'),
  polyfillDetail = require('./polyfills/polyfill.details'),
  revealPubSub = require('./modules/moj.reveal-pub-sub'),
  selectedOption = require('./modules/moj.selected-option'),
  formHintReveal = require('./modules/moj.reveal-hints'),
  removeMultiple = require('./modules/moj.remove-multiple'),
  sessionPrompt = require('./modules/moj.session-prompt');

revealPubSub.init();

var isClaimPath = function () {
  return !!location.pathname.match(/^\/apply\/.*/);
};

if (isClaimPath()) {
  sessionPrompt.init();
}
