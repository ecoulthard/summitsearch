const PlaceObject = {
  local_index: 0,
  active_index: null,
  borderPoints: [],
  pathCoordinates: [],
  path: null,
  thinPath: null,

  // If the place was submitted then this line would close the loop
  // It is drawn as a reference to show people they don't have to close the loop themselves.
  updateThinPlaceConnectingLine() {
    if (this.thinPath !== null) {
      this.thinPath.setMap(null);
    }
    if (this.pathCoordinates.length > 2) {
      this.thinPath = new google.maps.Polyline({
        path: [this.pathCoordinates[0], this.pathCoordinates[this.pathCoordinates.length - 1]],
        strokeColor: '#00FF00',
        strokeOpacity: 0.5,
        strokeWeight: 1,
        map: window.map
      });
    }
  },

  // Called when loading a pre-existing border point (editing an existing place)
  loadBorderPoint(id) {
    this.borderPoints[id] = new BorderPoint(
      id,
      $(`#place_border_points_attributes_${id}_latitude`).val(),
      $(`#place_border_points_attributes_${id}_longitude`).val()
    );
    this.pathCoordinates[id] = this.borderPoints[id].latLon;
    this.updateThinPlaceConnectingLine();
    this.local_index = this.borderPoints.length;
    this.active_index = this.local_index - 1;
  },

  // Adds the new border point to the form
  addNewBorderPoint(button, association, content) {
    const latVal = $("#Latitude").val();
    const lngVal = $("#Longitude").val();
    let latitude = window.convertToDecimal ? window.convertToDecimal(latVal) : latVal;
    let longitude = window.convertToDecimal ? window.convertToDecimal(lngVal) : lngVal;
    $("#Latitude").val(latitude);
    $("#Longitude").val(longitude);

    if (latitude === "" || longitude === "" || isNaN(latitude) || isNaN(longitude)) {
      alert("Latitude and Longitude must be numbers at most 500km away from the center of this place and no more than 100km away from the previous waypoint added.");
      return;
    }

    content = content.replace(new RegExp(`new_${association}`, "g"), this.local_index);
    content = content.replace('type="hidden" />', `type="hidden" value="${latitude}" />`);
    content = content.replace('type="hidden" />', `type="hidden" value="${longitude}" />`);
    content = content.replace('type="hidden" />', `type="hidden" value="${this.local_index}" />`);
    $(button).after(content);

    this.borderPoints[this.local_index] = new BorderPoint(this.local_index, latitude, longitude);
    this.pathCoordinates.push(this.borderPoints[this.local_index].latLon);

    if (this.active_index !== null && this.active_index !== undefined) {
      if (this.borderPoints[this.active_index]) {
        this.borderPoints[this.active_index].marker.setIcon(); // Reset parent waypoint icon
      }
      if (this.path) {
        this.path.setMap(null);
      }
      this.path = new google.maps.Polyline({
        path: this.pathCoordinates,
        strokeColor: '#FF0000',
        strokeOpacity: 1.0,
        strokeWeight: 2,
        map: window.map
      });
    }

    this.updateThinPlaceConnectingLine();
    this.active_index = this.local_index;
    this.local_index++;
  },

  // Remove point at index
  removeBorderPoint(index) {
    this.borderPoints[index].destroy();

    // Remove point from polyline
    const marker = this.borderPoints[index].marker;
    let i = 0;
    for (i = 0; i < this.pathCoordinates.length; i++) {
      const coord = this.pathCoordinates[i];
      if (marker.getPosition().lat() === coord.lat() && marker.getPosition().lng() === coord.lng()) {
        break;
      }
    }
    this.pathCoordinates.splice(i, 1);
    if (this.path) {
      this.path.setMap(null);
    }
    this.path = new google.maps.Polyline({
      path: this.pathCoordinates,
      strokeColor: '#FF0000',
      strokeOpacity: 1.0,
      strokeWeight: 2,
      map: window.map
    });
    this.updateThinPlaceConnectingLine();

    // Need to assign active index to next available point
    if (this.active_index === index) {
      for (let j = parseInt(index) - 1; j >= 1; j--) {
        const point = this.borderPoints[j];
        if (point && !point._destroy) {
          point.marker.setIcon("/assets/markers/yellow-dot.png");
          this.active_index = j;
          break;
        }
      }
    }
  },

  moveBorderPoint(index, latitude, longitude) {
    this.borderPoints[index].setPosition(latitude, longitude);
    this.redraw();
  },

  redraw() {
    if (this.path) {
      this.path.setMap(null);
    }
    this.pathCoordinates = [];
    for (const point of this.borderPoints) {
      if (point && !point._destroy) {
        this.pathCoordinates.push(point.latLon);
      }
    }
    this.path = new google.maps.Polyline({
      path: this.pathCoordinates,
      strokeColor: '#FF0000',
      strokeOpacity: 1.0,
      strokeWeight: 2,
      map: window.map
    });
    this.updateThinPlaceConnectingLine();
  }
};

window.Place = PlaceObject;
