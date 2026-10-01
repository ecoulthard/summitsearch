// Google Analytics Code
if (typeof doNotTrack === "undefined" || !doNotTrack) {
  window._gaq = window._gaq || [];
  window._gaq.push(['_setAccount', 'UA-26814612-1']);
  window._gaq.push(['_trackPageview']);

  (function() {
    const ga = document.createElement("script");
    ga.type = "text/javascript";
    ga.async = true;
    ga.src = (document.location.protocol === "https:" ? "https://" : "http://") + "stats.g.doubleclick.net/dc.js";
    const s = document.getElementsByTagName("script")[0];
    if (s && s.parentNode) {
      s.parentNode.insertBefore(ga, s);
    }
  })();
}

const isTouchDevice = () => ('ontouchstart' in window) || (navigator.maxTouchPoints > 0) || (window.Modernizr && window.Modernizr.touch);

// Converts the string coord to decimal if in deg:min:sec or deg:min else returns string as is
window.convertToDecimal = function(coord) {
  if (!coord || typeof coord !== "string") return coord;
  coord = coord.trim();
  const colonIndex = coord.indexOf(":");
  if (colonIndex === -1) return coord;

  let dec = parseInt(coord.substring(0, colonIndex), 10);
  const sign = dec >= 0 ? 1 : -1;

  // If deg:min:sec (e.g. 51:12:30 or -115:30:15)
  if (/^-?\d{1,3}:\d{1,2}:\d{1,2}$/.test(coord)) {
    const lastColon = coord.lastIndexOf(":");
    const min = parseFloat(coord.substring(colonIndex + 1, lastColon));
    const sec = parseFloat(coord.substring(lastColon + 1));
    dec += sign * (min / 60.0 + sec / 3600.0);
    return dec;
  }
  // If deg:min (e.g. 51:12.5)
  else if (/^-?\d{1,3}:\d{1,2}(\.\d*)?$/.test(coord)) {
    const min = parseFloat(coord.substring(colonIndex + 1));
    dec += sign * (min / 60.0);
    return dec;
  }
  return coord;
};

window.onAppReady = window.onAppReady || function(callback) {
  if (document.readyState !== "loading") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
  document.addEventListener("turbo:load", callback);
};

let photo_load_called = false;

function loadPhotosIfOnScreen(getpath) {
  if (photo_load_called) return;
  const target = $('#photos_go_here');
  if (!target.length) return;

  const hT = target.offset().top;
  const wH = $(window).height();
  const wS = $(window).scrollTop();

  if (wS + wH < hT - 300) return;

  photo_load_called = true;
  const object_id = target.data('object_id');
  target.html('<p style="font-size:larger"><span class="ajax-loader"></span> Loading photos</p>');
  const resolvedPath = getpath.replace("{{id}}", object_id);

  $.get(resolvedPath, function(data) {
    $("#photos_go_here").replaceWith(data);
    if ($.fn.button) {
      $("input:submit, input:button, button, .linkButton").button();
    }
  });
}

// Called on load in the show page for something that has photos
window.setupPhotoLoad = function(getpath) {
  photo_load_called = false;
  loadPhotosIfOnScreen(getpath);

  $(window).off('scroll.photoLoad resize.photoLoad').on('scroll.photoLoad resize.photoLoad', function() {
    loadPhotosIfOnScreen(getpath);
  });
};

// jQuery insertAtCaret plugin
if (window.jQuery) {
  jQuery.fn.extend({
    insertAtCaret: function(myValue) {
      return this.each(function() {
        if (document.selection) {
          this.focus();
          const sel = document.selection.createRange();
          sel.text = myValue;
          this.focus();
        } else if (this.selectionStart || this.selectionStart === 0 || this.selectionStart === '0') {
          const startPos = this.selectionStart;
          const endPos = this.selectionEnd;
          const scrollTop = this.scrollTop;
          this.value = this.value.substring(0, startPos) + myValue + this.value.substring(endPos, this.value.length);
          this.focus();
          this.selectionStart = startPos + myValue.length;
          this.selectionEnd = startPos + myValue.length;
          this.scrollTop = scrollTop;
        } else {
          this.value += myValue;
          this.focus();
        }
      });
    }
  });
}

function initSharedUI() {
  const isTouch = isTouchDevice();

  if (!isTouch) {
    $("#banner").on("click", function(event) {
      if ($(event.target).is("#banner") || $(event.target).is("#BannerLogo")) {
        $("html").css({ cursor: "wait" });
        const href = $("#BannerLink").prop("href");
        if (href) {
          if (window.Turbo) window.Turbo.visit(href);
          else window.location.href = href;
        }
      }
    });
  } else {
    $(".clickable, #menu li > a").on("click", function(e) {
      const firstclick = $(this).hasClass("firstClick");
      $(".clickable, #menu li > a").removeClass("firstClick");
      if (!firstclick) {
        $(this).addClass("firstClick");
        e.preventDefault();
        return false;
      }
    });

    $("#banner").on("click", function() {
      $("#menu").css("left", "0px");
    });
  }

  // Dialogs
  if ($.fn.dialog) {
    if ($("#dlgSignin").length) {
      $("#dlgSignin").dialog({ autoOpen: false, modal: true, width: 350 });
      $(".signin").on("click", function(e) {
        $("#dlgSignin").dialog("open");
        e.preventDefault();
        return false;
      });
    }

    if ($("#dlgSignup").length) {
      $("#dlgSignup").dialog({ autoOpen: false, modal: true, width: 350 });
      $(".signup").on("click", function(e) {
        $("#dlgSignup").dialog("open");
        e.preventDefault();
        return false;
      });
    }
  }

  // Captions on hover / touch
  if (!isTouch) {
    $(document).on('mouseenter', '.entry, .thumbDiv', function() {
      $(this).children('.captionDiv, .abstractDiv').show();
    });
    $(document).on('mouseleave', '.entry, .thumbDiv', function() {
      $(this).children('.captionDiv, .abstractDiv').hide();
    });
  } else {
    $(document).on('click', '.entry, .thumbDiv', function() {
      $(".entry, .thumbDiv").children('.captionDiv, .abstractDiv').hide();
      $(this).children('.captionDiv, .abstractDiv').show();
    });
  }

  // Tooltip
  if ($.fn.tooltip) {
    $(document).tooltip({
      items: ".showHover",
      show: false,
      hide: false,
      close: false,
      position: {
        my: "center top",
        at: "center bottom"
      },
      classes: {
        "ui-tooltip": "ui-tooltip"
      },
      content: function() {
        const element = $(this);
        if (element.is(".showHover")) {
          return element.children(".hover:first").html();
        }
        return "";
      }
    });
  }

  // Clickable items
  $(document).on('click', '.clickable', function(event) {
    if ($(event.target).is("a") || $(event.target).parent().is("a")) {
      return true;
    }
    if (!isTouch || $(this).hasClass("firstClick")) {
      const link = $(this).find("a:first")[0];
      if (link && link.href) {
        if (window.Turbo) window.Turbo.visit(link.href);
        else window.location.href = link.href;
      }
    }
  });

  // Notice timeout
  setTimeout(function() {
    $("#notice").slideUp('slow');
  }, 10000);

  // jQuery UI buttons
  if ($.fn.button) {
    $("input:submit, input:button, button, .linkButton").button();
  }

  $(document).on('nested:fieldAdded', function(event) {
    if (event.field && $.fn.button) {
      event.field.find("input:submit, input:button, button, .linkButton").button();
    }
  });

  // Toggle buttons
  $('.toggleButton').each(function() {
    const toggleText = $(this).prevAll().find('.place_description');
    if (toggleText.length === 0 || (toggleText.prop("scrollHeight") <= toggleText.prop("offsetHeight"))) {
      $(this).hide();
    } else if ($.fn.button) {
      $(this).button();
    }
  });

  $(document).on("click", '.toggleButton', function(e) {
    e.stopPropagation();
    const toggleText = $(this).prevAll().find('.place_description');
    const buttonText = $(this).text();
    if (buttonText.indexOf("Read more") === 0) {
      const h = toggleText.prop("scrollHeight");
      toggleText.animate({ maxHeight: h });
      $(this).text("Read less" + buttonText.substring(9));
    } else {
      toggleText.animate({ maxHeight: '600px' });
      $(this).text("Read more" + buttonText.substring(9));
    }
  });

  // Block enter
  $(document).on("keypress", '.noenter', function(e) {
    if (e.keyCode === 13 || e.which === 13) {
      e.preventDefault();
      return false;
    }
  });

  // MarkItUp editor
  if (typeof mySettings !== "undefined" && $.fn.markItUp) {
    mySettings.previewParserPath = "/markitup/preview";
    mySettings.onEnter = {
      keepDefault: false,
      replaceWith: "<br />\n"
    };
    $(".editor").markItUp(mySettings);
  }
}

window.onAppReady(function() {
  initSharedUI();
});
