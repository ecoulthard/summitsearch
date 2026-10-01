window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.trip_reports.show').length && window.setupPhotoLoad) {
    window.setupPhotoLoad("/trip_reports/{{id}}/photos");
  }
});
