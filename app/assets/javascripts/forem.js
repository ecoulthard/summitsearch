window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
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
