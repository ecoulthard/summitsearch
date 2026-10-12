window.onAppReady = window.onAppReady || function(callback) {
  let initialFired = false;
  const run = function() {
    callback();
  };

  if (document.readyState !== "loading") {
    initialFired = true;
    setTimeout(run, 0);
  } else {
    document.addEventListener("DOMContentLoaded", function() {
      initialFired = true;
      run();
    }, { once: true });
  }

  document.addEventListener("turbo:load", function() {
    if (initialFired) {
      initialFired = false;
      return;
    }
    run();
  });
};

window.onAppReady(function() {
  if ($('body.albums.show').length && window.setupPhotoLoad) {
    window.setupPhotoLoad("/albums/{{id}}/photos");
  }
});
