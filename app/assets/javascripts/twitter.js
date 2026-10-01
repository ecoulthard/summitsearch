// Twitter widgets integration with Turbo Drive compatibility
let twttrEventsBound = false;

window.renderTweetButtons = function() {
  $('.twitter-share-button').each(function() {
    const button = $(this);
    if (!button.data('url')) {
      button.attr('data-url', document.location.href);
    }
    if (!button.data('text')) {
      button.attr('data-text', document.title);
    }
  });

  if (typeof twttr !== "undefined" && twttr.widgets) {
    twttr.widgets.load();
  }
};

window.loadTwitterSDK = function() {
  if ($('.twitter-share-button').length > 0) {
    $.getScript('//platform.twitter.com/widgets.js');
  }
};

window.bindTwitterEventHandlers = function() {
  $(document).on('turbo:load ready', window.renderTweetButtons);
  twttrEventsBound = true;
};

$(function() {
  window.loadTwitterSDK();
  if (!twttrEventsBound) {
    window.bindTwitterEventHandlers();
  }
});
