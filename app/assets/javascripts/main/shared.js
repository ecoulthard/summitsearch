let busy = false;

window.Main = {
  // Show menu bar
  showMenuBar() {
    $("#menuSearchBar").show();
    $("#searchDiv").width(Math.max(150, $("body").width() - $("#menuDiv").width()));
  },

  // Loads new photos for the user corresponding to the summary div
  loadUserPhotos(summaryDiv, type) {
    if (!summaryDiv.hasClass('User_Photo_Summary')) {
      summaryDiv = summaryDiv.parents('.User_Photo_Summary');
    }
    const elemId = summaryDiv.prop('id') || "";
    const user_id = elemId.substring(elemId.indexOf(":") + 1);
    const displayDivID = "#divUserPhotos" + user_id;

    if (busy || $(displayDivID).is(':visible')) return;
    busy = true;

    $('.User_Photo_Summary').css('background-color', 'white');
    summaryDiv.css('background-color', '#bbb');

    const getpath = `/users/${user_id}/photos?type=${type}`;
    $('.User_Photos').html('<p style="font-size:larger"><span class="ajax-loader"></span> Loading member photos</p>');

    $.get(getpath, function(data) {
      $(".User_Photos").html(data);
      busy = false;
    });
  },

  // Init callbacks for user photo summaries
  initPhotoSummaries(type) {
    busy = false;
    const isTouch = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0) || (window.Modernizr && window.Modernizr.touch);

    if (!isTouch) {
      $('.User_Photo_Summary').on('mouseenter', (e) => {
        this.loadUserPhotos($(e.target), type);
      });
    } else {
      $('.User_Photo_Summary').on('click', (e) => {
        this.loadUserPhotos($(e.target), type);
      });
    }
  }
};
