window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

// Autocomplete search handling
window.onAppReady(function() {
  if ($('body.default').length && $('#search').length && $.fn.autocomplete) {
    $('#search').autocomplete({
      minLength: 4,
      position: {
        my: "right top",
        at: "right bottom"
      },
      source: function(request, response) {
        $.ajax({
          url: "/search.json",
          dataType: "json",
          data: {
            search: request.term,
            open_best_result: "off"
          },
          async: true,
          success: function(data) {
            response(data);
          },
          error: function() {}
        });
      },
      select: function(event, ui) {
        $("*").css({ cursor: "wait" });
        let targetUrl = null;
        if (ui.item.album) {
          targetUrl = `/albums/${ui.item.id}`;
        } else if (ui.item.place) {
          targetUrl = `/places/${ui.item.id}`;
        } else if (ui.item.photo) {
          targetUrl = `/photos/${ui.item.id}`;
        } else if (ui.item.route) {
          targetUrl = `/routes/${ui.item.id}`;
        } else if (ui.item.trip_report) {
          targetUrl = `/trip_reports/${ui.item.id}`;
        } else if (ui.item.user) {
          targetUrl = `/users/${ui.item.id}`;
        }

        if (targetUrl) {
          if (window.Turbo) {
            window.Turbo.visit(targetUrl);
          } else {
            window.location.href = targetUrl;
          }
        }
      }
    });
  }
});
