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
  if ($('body.forem').length && !$('body.ie7').length && $.fn.jMenu) {
    $("#jMenu").jMenu({
      ulWidth: 150,
      TimeBeforeOpening: 100,
      TimeBeforeClosing: 400,
      absoluteTop: 24,
      absoluteLeft: -20
    });
  }
});
