window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.places.show').length && window.setupPhotoLoad) {
    window.setupPhotoLoad("/places/{{id}}/photos");
  }
});
