// Facebook SDK integration with Turbo Drive compatibility
let fbRoot = null;
let fbEventsBound = false;

window.saveFacebookRoot = function() {
  const root = $('#fb-root');
  if (root.length > 0) {
    fbRoot = root.detach();
  }
};

window.restoreFacebookRoot = function() {
  if ($('#fb-root').length > 0) {
    if (fbRoot) $('#fb-root').replaceWith(fbRoot);
  } else if (fbRoot) {
    $('body').append(fbRoot);
  }
};

window.initializeFacebookSDK = function() {
  if (typeof FB === "undefined") return;

  FB.init({
    appId: typeof facebookAppId !== "undefined" ? facebookAppId : null,
    channelUrl: typeof facebookChannelUrl !== "undefined" ? facebookChannelUrl : null,
    status: false,
    cookie: true,
    xfbml: true
  });

  FB.Event.subscribe('edge.create', function(response) {
    if (typeof socialUpdate === 'function') {
      socialUpdate('true', '');
    }
  });

  FB.Event.subscribe('edge.remove', function(response) {
    if (typeof socialUpdate === 'function') {
      socialUpdate('false', '');
    }
  });
};

window.loadFacebookSDK = function() {
  window.fbAsyncInit = window.initializeFacebookSDK;
  if ($('.fb-like, #fb-root').length > 0) {
    $.getScript('//connect.facebook.net/en_US/all.js#xfbml=1');
  }
};

window.bindFacebookEvents = function() {
  $(document)
    .on('turbo:before-render', window.saveFacebookRoot)
    .on('turbo:render', window.restoreFacebookRoot)
    .on('turbo:load ready', function() {
      if (typeof FB !== "undefined" && FB.XFBML) {
        FB.XFBML.parse();
      }
    });
  fbEventsBound = true;
};

$(function() {
  window.loadFacebookSDK();
  if (!fbEventsBound) {
    window.bindFacebookEvents();
  }
});
