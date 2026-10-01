var Waypoint = window.Waypoint = class Waypoint {
  constructor(id, parent_index, title, latitude, longitude, height, distance, height_gain, height_loss, description, icon, icon_src, window_content) {
    this.id = id;
    this.parent_index = parent_index;
    this.title = title;
    this.latitude = latitude;
    this.longitude = longitude;
    this.height = height;
    this.distance = distance;
    this.height_gain = height_gain;
    this.height_loss = height_loss;
    this.description = description;
    this.icon = icon;
    this.icon_src = icon_src;
    this.window_content = window_content;

    this._destroy = false;
    this.latLon = new google.maps.LatLng(this.latitude, this.longitude);
    this.marker = new google.maps.Marker({
      position: this.latLon,
      map: window.map,
      title: "A waypoint",
      draggable: true,
      icon: "/assets/markers/yellow-dot.png"
    });
    this.infowindow = new google.maps.InfoWindow({
      content: window.Route ? window.Route.setUpWindowContent(this.id, this.window_content) : ""
    });
    this.window_open = false; // info window is closed by default
    this.path = null;

    if (!this.isRoot()) {
      if (this.parent()) {
        this.parent().resetIcon(); // Reset parent waypoint icon
        this.path = new google.maps.Polyline({
          path: [this.parent().marker.getPosition(), this.latLon],
          strokeColor: '#FF0000',
          strokeOpacity: 1.0,
          strokeWeight: 2,
          map: window.map
        });
      }
    }

    // If height is 0 it is probably a new waypoint so look up elevation using Google's elevation service
    if (this.height === 0) {
      this.getElevation();
    }

    this.setHeightChange();

    // If not set yet compute the distance to the trailhead from this point
    if (!this.isRoot() && this.distance === 0.0 && this.parent()) {
      this.setDistance(this.parent().distance + (google.maps.geometry.spherical.computeDistanceBetween(this.latLon, this.parent().latLon) / 1000.0));
    }

    this.addEvents();
  }

  // Ask Google for elevation
  getElevation() {
    const index = this.id;
    if (!window.Route || !window.Route.elevator) return;
    window.Route.elevator.getElevationForLocations({ locations: [this.latLon] }, (results, status) => {
      if (status === google.maps.ElevationStatus.OK) {
        if (results && results[0] && results[0].elevation !== undefined) {
          const wp = window.Route.getWaypoint(index);
          if (wp) wp.setHeight(Math.round(results[0].elevation));
        } else {
          window.Route.removeWaypoint(index);
          alert("Couldn't retrieve elevation of waypoint from Google. You will need to re-enter the waypoint.");
        }
      } else {
        window.Route.removeWaypoint(index);
        alert(`Google's elevation service failed due to: ${status}. You will need to re-enter the waypoint.`);
      }
    });
  }

  // Add functions to handle events for the waypoint
  addEvents() {
    const index = this.id;

    // When the marker is clicked open the window and load the object's values
    this.markerClickListener = google.maps.event.addListener(this.marker, 'click', () => {
      const waypoint = window.Route.getWaypoint(index);
      if (waypoint) {
        if (waypoint.window_open) {
          window.Route.activateWaypoint(index);
        }
        waypoint.infowindow.open(window.map, waypoint.marker);
      }
    });

    // When an info window is opened load values into it
    this.infoWindowOpenListener = google.maps.event.addListener(this.infowindow, 'domready', () => {
      const wp = window.Route.getWaypoint(index);
      if (wp) wp.openWindow();
      const fieldset = $(`#bubble_fieldset_${index}`);
      fieldset.children("BR").remove();
      if ($.fn.TextAreaExpander) {
        fieldset.find("textarea.expand").TextAreaExpander();
      }
    });

    // When an info window is closed update flag
    this.infoWindowCloseListener = google.maps.event.addListener(this.infowindow, 'closeclick', () => {
      const wp = window.Route.getWaypoint(index);
      if (wp) wp.setWindowOpen(false);
    });

    // Right click to remove waypoint
    this.markerRightClickListener = google.maps.event.addListener(this.marker, 'rightclick', () => {
      window.Route.removeWaypoint(index);
    });

    // Path click to insert waypoint
    if (this.path) {
      this.pathClickListener = google.maps.event.addListener(this.path, 'click', (event) => {
        window.Route.insertWaypoint(index, event.latLng.lat(), event.latLng.lng());
      });
    }

    // Drag start
    this.dragstartListener = google.maps.event.addListener(this.marker, 'dragstart', () => {
      const wp = window.Route.getWaypoint(index);
      if (wp) wp.infowindow.close();
    });

    // Drag end
    this.dragendListener = google.maps.event.addListener(this.marker, 'dragend', (event) => {
      const waypoint = window.Route.getWaypoint(index);
      if (!waypoint) return;

      if (google.maps.geometry.spherical.computeDistanceBetween(event.latLng, new google.maps.LatLng(waypoint.latitude, waypoint.longitude)) > 100000) {
        waypoint.marker.setPosition(waypoint.latLon);
        alert("Waypoints cannot be moved by more than 100km.");
        return;
      }
      waypoint.setLatitude(event.latLng.lat());
      waypoint.setLongitude(event.latLng.lng());
      waypoint.latLon = event.latLng;
      waypoint.redrawLines();
      waypoint.getElevation();
      setTimeout(() => {
        window.Route.computeDistances();
      }, 500);
    });
  }

  removeEvents() {
    if (this.markerClickListener) google.maps.event.removeListener(this.markerClickListener);
    if (this.infoWindowOpenListener) google.maps.event.removeListener(this.infoWindowOpenListener);
    if (this.infoWindowCloseListener) google.maps.event.removeListener(this.infoWindowCloseListener);
    if (this.markerRightClickListener) google.maps.event.removeListener(this.markerRightClickListener);
    if (this.pathClickListener) google.maps.event.removeListener(this.pathClickListener);
    if (this.dragstartListener) google.maps.event.removeListener(this.dragstartListener);
    if (this.dragendListener) google.maps.event.removeListener(this.dragendListener);
  }

  openWindow() {
    this.window_open = true;
    $(`#title_${this.id}`).val(this.title);
    $(`#latitude_${this.id}`).val(this.latitude);
    $(`#longitude_${this.id}`).val(this.longitude);
    $(`#height_${this.id}`).val(this.height);
    $(`#distance_${this.id}`).text(Math.round(this.distance * 100) / 100);
    $(`#height_gain_${this.id}`).text(this.height_gain);
    $(`#height_loss_${this.id}`).text(this.height_loss);
    $(`#description_${this.id}`).val(this.description);
    $(`#icon_${this.id}_${this.icon}`).prop("checked", true);
  }

  destroy() {
    if (this.isRoot() && this.numChildren() > 1) return;
    this.infowindow.close();
    this.marker.setMap(null);
    if (this.path) {
      this.path.setMap(null);
    }
    this.setDestroy(true);
  }

  isRoot() {
    return this.parent_index === null || this.parent_index === undefined || isNaN(this.parent_index) || this.parent_index === this.id || this.parent_index < 0;
  }

  parent() {
    if (!this.isRoot() && window.Route) {
      return window.Route.getWaypoint(this.parent_index);
    }
    return null;
  }

  midLatitude() {
    if (!this.isRoot() && this.parent()) {
      return (parseFloat(this.latitude) + parseFloat(this.parent().latitude)) / 2.0;
    }
    return parseFloat(this.latitude) + 0.005;
  }

  midLongitude() {
    if (!this.isRoot() && this.parent()) {
      return (parseFloat(this.longitude) + parseFloat(this.parent().longitude)) / 2.0;
    }
    return parseFloat(this.longitude) + 0.005;
  }

  setID(newID) {
    this.id = newID;
    this.infowindow.setContent(window.Route.setUpWindowContent(this.id, this.window_content));
    this.removeEvents();
    this.addEvents();
  }

  setTitle(newTitle) {
    this.title = newTitle;
    if (this.icon_src === null || this.icon_src === "") {
      this.icon_src = "/assets/markers/green-dot.png";
      this.marker.setIcon(this.icon_src);
    }
    $(`#route_waypoints_attributes_${this.id}_title`).val(newTitle);
  }

  setLatitude(newLatitude) {
    if (typeof newLatitude === "string") {
      newLatitude = window.convertToDecimal ? window.convertToDecimal(newLatitude) : newLatitude;
      if (newLatitude === "" || isNaN(newLatitude)) {
        $(`#latitude_${this.id}`).val(this.latitude);
        alert("Latitude must be a number.");
        return;
      }
    }
    const latLng = new google.maps.LatLng(newLatitude, this.longitude);
    if (google.maps.geometry.spherical.computeDistanceBetween(this.marker.getPosition(), latLng) > 100000) {
      $(`#latitude_${this.id}`).val(this.latitude);
      alert("Waypoints cannot be moved by more than 100km apart.");
      return;
    }
    this.latitude = newLatitude;
    $(`#route_waypoints_attributes_${this.id}_latitude`).val(newLatitude);
    if (this.marker.getPosition().lat() !== this.latitude) {
      this.latLon = new google.maps.LatLng(this.latitude, this.longitude);
      this.marker.setPosition(this.latLon);
      this.redrawLines();
    }
  }

  setLongitude(newLongitude) {
    if (typeof newLongitude === "string") {
      newLongitude = window.convertToDecimal ? window.convertToDecimal(newLongitude) : newLongitude;
      if (newLongitude === "" || isNaN(newLongitude)) {
        $(`#longitude_${this.id}`).val(this.longitude);
        alert("Longitude must be a number.");
        return;
      }
    }
    const latLng = new google.maps.LatLng(this.latitude, newLongitude);
    if (google.maps.geometry.spherical.computeDistanceBetween(this.marker.getPosition(), latLng) > 100000) {
      $(`#longitude_${this.id}`).val(this.longitude);
      alert("Waypoints cannot be moved by more than 100km apart.");
      return;
    }
    this.longitude = newLongitude;
    $(`#route_waypoints_attributes_${this.id}_longitude`).val(newLongitude);
    if (this.marker.getPosition().lng() !== this.longitude) {
      this.latLon = new google.maps.LatLng(this.latitude, this.longitude);
      this.marker.setPosition(this.latLon);
      this.redrawLines();
    }
  }

  setParentIndex(newParentIndex) {
    this.parent_index = newParentIndex;
    $(`#route_waypoints_attributes_${this.id}_parent_index`).val(newParentIndex);
    this.computeDistance();
  }

  setHeight(newHeight) {
    this.height = newHeight;
    $(`#route_waypoints_attributes_${this.id}_height`).val(newHeight);
    if (window.Route) window.Route.computeDistances();
  }

  getHeightChangeToParent() {
    if (this.isRoot() || !this.parent()) {
      return 0;
    }
    return this.height - this.parent().height;
  }

  setHeightChange() {
    if (this.isRoot() || !this.parent()) {
      this.height_gain = 0;
      this.height_loss = 0;
    } else {
      const heightChange = this.getHeightChangeToParent();
      this.height_gain = this.parent().height_gain || 0;
      this.height_loss = this.parent().height_loss || 0;
      if (heightChange >= 0) {
        this.height_gain += heightChange;
      } else {
        this.height_loss -= heightChange;
      }
    }
    $(`#route_waypoints_attributes_${this.id}_height_gain`).val(this.height_gain);
    $(`#route_waypoints_attributes_${this.id}_height_loss`).val(this.height_loss);
  }

  distToParent() {
    if (this.isRoot() || !this.parent()) {
      return 0.0;
    }
    return google.maps.geometry.spherical.computeDistanceBetween(this.latLon, this.parent().latLon) / 1000.0;
  }

  computeDistance() {
    if (this.isRoot() || !this.parent()) {
      this.setDistance(0.0);
    } else {
      this.setDistance(this.parent().distance + this.distToParent());
    }
  }

  setDistance(newDistance) {
    this.distance = newDistance;
    $(`#route_waypoints_attributes_${this.id}_distance`).val(newDistance);
  }

  setDescription(newDescription) {
    this.description = newDescription;
    if (this.icon_src === null || this.icon_src === "") {
      this.icon_src = "/assets/markers/green-dot.png";
      this.marker.setIcon(this.icon_src);
    }
    $(`#route_waypoints_attributes_${this.id}_description`).val(newDescription);
  }

  resetIcon() {
    this.marker.setIcon(this.icon_src);
  }

  setIcon(newIcon, icon_src) {
    this.icon = newIcon;
    this.icon_src = icon_src;
    this.marker.setIcon(icon_src);
    $(`#route_waypoints_attributes_${this.id}_icon`).val(newIcon);
  }

  setWindowOpen(open) {
    this.window_open = open;
  }

  setDestroy(newDestroy) {
    this._destroy = newDestroy;
    $(`#route_waypoints_attributes_${this.id}__destroy`).val(newDestroy);
  }

  setPath() {
    if (!this.isRoot() && this.parent()) {
      if (this.path) {
        this.path.setPath([this.parent().latLon, this.latLon]);
      } else {
        this.path = new google.maps.Polyline({
          path: [this.parent().latLon, this.latLon],
          strokeColor: '#FF0000',
          strokeOpacity: 1.0,
          strokeWeight: 2,
          map: window.map
        });
      }
    } else if (this.path) {
      this.path.setMap(null);
      this.path = null;
    }
  }

  redrawLines() {
    this.setPath();
    if (!window.Route || !window.Route.waypoints) return;
    for (let i = this.id + 1; i < window.Route.local_index; i++) {
      const waypoint = window.Route.waypoints[i];
      if (waypoint && !waypoint._destroy) {
        waypoint.setPath();
      }
    }
  }

  save() {
    $(`#route_waypoints_attributes_${this.id}_parent_index`).val(this.parent_index);
    $(`#route_waypoints_attributes_${this.id}_title`).val(this.title);
    $(`#route_waypoints_attributes_${this.id}_latitude`).val(this.latitude);
    $(`#route_waypoints_attributes_${this.id}_longitude`).val(this.longitude);
    $(`#route_waypoints_attributes_${this.id}_height`).val(this.height);
    $(`#route_waypoints_attributes_${this.id}_distance`).val(this.distance);
    $(`#route_waypoints_attributes_${this.id}_height_gain`).val(this.height_gain);
    $(`#route_waypoints_attributes_${this.id}_height_loss`).val(this.height_loss);
    $(`#route_waypoints_attributes_${this.id}_description`).val(this.description);
    $(`#route_waypoints_attributes_${this.id}_icon`).val(this.icon);
    $(`#route_waypoints_attributes_${this.id}__destroy`).val(this._destroy);
  }

  numChildren() {
    let count = 0;
    if (!window.Route || !window.Route.waypoints) return 0;
    for (let i = this.id + 1; i < window.Route.local_index; i++) {
      const waypoint = window.Route.waypoints[i];
      if (waypoint && !waypoint._destroy && waypoint.parent_index === this.id) {
        count++;
      }
    }
    return count;
  }
}

window.Waypoint = Waypoint;
