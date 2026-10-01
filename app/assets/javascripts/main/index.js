window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.main.index').length && window.Main) {
    window.Main.showMenuBar();
    window.Main.initPhotoSummaries('new');
  }
});
