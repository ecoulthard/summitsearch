window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

window.onAppReady(function() {
  if ($('body.nomenu').length) {
    // Make banner clickable to return to home
    $("#short_banner").on("click", function() {
      const href = $(this).children("a").prop("href");
      if (href) {
        if (window.Turbo) {
          window.Turbo.visit(href);
        } else {
          window.location.href = href;
        }
      }
    });

    // Prevent double click submits
    $(document).on("submit", "form", function() {
      $("input:submit, BUTTON").prop("disabled", true);
      return true;
    });

    // Block pressing enter when we don't want it to submit a form
    $(document).on("keypress", ".noenter", function(e) {
      if (e.keyCode === 13 || e.which === 13) {
        e.preventDefault();
        return false;
      }
    });

    $(document).on("nested:fieldAdded", function(e) {
      if (e.field && $.fn.TextAreaExpander) {
        e.field.find("textarea.expand").TextAreaExpander();
      }
    });
  }
});
