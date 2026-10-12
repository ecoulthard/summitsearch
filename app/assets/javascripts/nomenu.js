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
