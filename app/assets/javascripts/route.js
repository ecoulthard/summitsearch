const RouteObject = {
  allow_branches: true,
  centerLatLng: null,
  elevator: null,
  active_index: null,
  local_index: 0,
  waypoints: [],

  coordinatesTooFarAway(latitude, longitude) {
    const latLng = new google.maps.LatLng(latitude, longitude);
    if (this.active_index !== null && this.waypoints[this.active_index]) {
      return google.maps.geometry.spherical.computeDistanceBetween(this.waypoints[this.active_index].marker.getPosition(), latLng) > 100000;
    }
    return false;
  },

  initRoute(branches_allowed, startLatitude, startLongitude, startContent, startName) {
    this.allow_branches = branches_allowed;
    this.centerLatLng = new google.maps.LatLng(startLatitude, startLongitude);
    const centerContentString = `<div class='reference_window'>${startContent}</div>`;
    const centerInfowindow = new google.maps.InfoWindow({ content: centerContentString });
    const centerMarker = new google.maps.Marker({
      position: this.centerLatLng,
      clickable: false,
      zIndex: -100,
      map: window.map,
      icon: "/assets/markers/center-dot.png",
      shape: {
        coord: [15, 18, 6],
        type: 'circle'
      },
      title: startName
    });

    google.maps.event.addListener(window.map, "click", this.mapClicked);
    this.elevator = new google.maps.ElevationService();
  },

  mapClicked(event) {
    if (window.Route && window.Route.local_index > 0) {
      for (let index = 0; index < window.Route.local_index; index++) {
        const waypoint = window.Route.waypoints[index];
        if (!waypoint || waypoint._destroy) continue;
        const lat = waypoint.latitude;
        const lng = waypoint.longitude;
        let threshold = 0.005;
        switch (window.map.getZoom()) {
          case 13: threshold = 0.003; break;
          case 14: threshold = 0.002; break;
          case 15: threshold = 0.001; break;
          case 16: threshold = 0.0005; break;
          case 17: threshold = 0.0003; break;
          case 18: threshold = 0.0001; break;
          case 19: threshold = 0.00005; break;
        }

        if (
          Math.abs(lat - event.latLng.lat()) < threshold &&
          Math.abs(lng - event.latLng.lng()) < threshold &&
          index !== window.Route.active_index &&
          window.Route.waypoints[window.Route.active_index] &&
          window.Route.waypoints[window.Route.active_index].parent_index !== index
        ) {
          $("#Latitude").val(window.Route.waypoints[index].latitude);
          $("#Longitude").val(window.Route.waypoints[index].longitude);
          $("#btnAddWaypoint").click();
          return;
        }
      }
    }

    $("#Latitude").val(event.latLng.lat());
    $("#Longitude").val(event.latLng.lng());
    $("#btnAddWaypoint").click();
  },

  setUpWindowContent(id, content) {
    if (!content) return "";
    content = content.replace('id="bubble_fieldset"', `id="bubble_fieldset_${id}"`);
    content = content.replace('id="title"', `id="title_${id}"`);
    content = content.replace('id="latitude"', `id="latitude_${id}"`);
    content = content.replace('id="longitude"', `id="longitude_${id}"`);
    content = content.replace('id="height"', `id="height_${id}"`);
    content = content.replace('id="distance"', `id="distance_${id}"`);
    content = content.replace('id="height_gain"', `id="height_gain_${id}"`);
    content = content.replace('id="height_loss"', `id="height_loss_${id}"`);
    content = content.replace('id="description"', `id="description_${id}"`);
    content = content.replace(/id="icon_/g, `id="icon_${id}_`);
    content = content.replace(/name="icon"/g, `name="icon_${id}"`);
    content = content.replace('onchange="title"', `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setTitle($(this).val());"`);
    content = content.replace('onchange="latitude"', `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setLatitude($(this).val());"`);
    content = content.replace('onchange="longitude"', `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setLongitude($(this).val());"`);
    content = content.replace('onchange="height"', `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setHeight(parseInt($(this).val()));"`);
    content = content.replace('onchange="description"', `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setDescription($(this).val());"`);
    content = content.replace(/onchange="icon"/g, `onchange="if(window.Route.waypoints[${id}]) window.Route.waypoints[${id}].setIcon($(this).val(),$(this).prev('img').prop('src'));"`);
    content = content.replace('onclick=";"', `onmouseup="window.Route.activateWaypoint(${id});"`);
    content = content.replace('onclick=";"', `onmouseup="window.Route.insertWaypointClicked(${id});"`);
    content = content.replace('onclick=";"', `onmouseup="if(confirm('Really delete this waypoint?')) window.Route.removeWaypoint(${id});"`);
    return content;
  },

  loadWaypoint(id, window_content, icon_src) {
    let parent_index = parseInt($(`#route_waypoints_attributes_${id}_parent_index`).val(), 10);
    if (isNaN(parent_index) || parent_index === this.local_index) {
      parent_index = null;
    }
    this.waypoints[id] = new Waypoint(
      id,
      parent_index,
      $(`#route_waypoints_attributes_${id}_title`).val(),
      $(`#route_waypoints_attributes_${id}_latitude`).val(),
      $(`#route_waypoints_attributes_${id}_longitude`).val(),
      parseInt($(`#route_waypoints_attributes_${id}_height`).val(), 10) || 0,
      parseFloat($(`#route_waypoints_attributes_${id}_distance`).val()) || 0.0,
      parseInt($(`#route_waypoints_attributes_${id}_height_gain`).val(), 10) || 0,
      parseInt($(`#route_waypoints_attributes_${id}_height_loss`).val(), 10) || 0,
      $(`#route_waypoints_attributes_${id}_description`).val(),
      $(`#route_waypoints_attributes_${id}_icon`).val(),
      icon_src,
      window_content
    );
    this.local_index = this.waypoints.length;
    this.active_index = this.local_index - 1;
    this.computeDistances();
  },

  addNewWaypoint(button, association, content, window_content) {
    const latVal = $("#Latitude").val();
    const lngVal = $("#Longitude").val();
    let latitude = window.convertToDecimal ? window.convertToDecimal(latVal) : latVal;
    let longitude = window.convertToDecimal ? window.convertToDecimal(lngVal) : lngVal;
    if (latitude === "" || longitude === "" || isNaN(latitude) || isNaN(longitude) || this.coordinatesTooFarAway(latitude, longitude)) {
      alert("Latitude and Longitude must be numbers at most 500km away from the center of this area and no more than 100km away from the previous waypoint added.");
      return;
    }
    content = content.replace(new RegExp(`new_${association}`, "g"), this.local_index);
    content = content.replace('type="hidden" />', `type="hidden" value="${latitude}" />`);
    content = content.replace('type="hidden" />', `type="hidden" value="${longitude}" />`);
    content = content.replace('type="hidden" />', `type="hidden" value="${this.local_index}" />`);
    content = content.replace('type="hidden" />', `type="hidden" value="${this.active_index}" />`);
    this.waypoints[this.local_index] = new Waypoint(this.local_index, this.active_index, "", latitude, longitude, 0, 0.0, 0, 0, "", "", null, window_content);
    this.active_index = this.local_index;
    this.local_index++;
    $(button).after(content);
    setTimeout(() => {
      this.computeDistances();
    }, 500);
  },

  insertWaypoint(insert_index, lat, lon) {
    if (this.waypoints[insert_index].isRoot()) {
      alert("Cannot insert a point before the first point");
      return;
    }
    $("#Latitude").val(lat);
    $("#Longitude").val(lon);
    $("#btnAddWaypoint").click();
    setTimeout(() => {
      this.continueInsertingWaypoint(insert_index);
    }, 500);
  },

  continueInsertingWaypoint(insert_index) {
    const inserted = this.waypoints[this.active_index];

    for (let index = this.local_index - 1; index >= insert_index; index--) {
      const waypoint = this.waypoints[index];
      waypoint.setID(index + 1);
      if (waypoint.parent_index >= insert_index) {
        waypoint.parent_index++;
      }
      this.waypoints[index + 1] = waypoint;
      waypoint.save();
    }

    const child = this.waypoints[insert_index + 1];
    inserted.setID(insert_index);
    inserted.parent_index = child.parent_index;
    inserted.computeDistance();
    inserted.setPath();
    this.waypoints[insert_index] = inserted;
    inserted.save();
    this.active_index = insert_index;

    child.setParentIndex(insert_index);
    child.setPath();
    child.save();
    this.computeDistances();
  },

  insertWaypointClicked(insert_index) {
    this.insertWaypoint(insert_index, this.waypoints[insert_index].midLatitude(), this.waypoints[insert_index].midLongitude());
  },

  activateWaypoint(index) {
    if ((this.allow_branches && this.active_index !== index) || (this.activeWaypoint() && this.activeWaypoint()._destroy)) {
      if (this.getWaypoint(index)) {
        this.getWaypoint(index).marker.setIcon("/assets/markers/yellow-dot.png");
      }
      if (this.activeWaypoint()) {
        this.activeWaypoint().resetIcon();
      }
      this.active_index = index;
    }
  },

  removeWaypoint(index) {
    const removed = this.getWaypoint(index);
    if (!removed) return;
    if (removed.isRoot() && removed.numChildren() > 1) {
      alert("Cannot remove the root point since this will disconnect the route");
      return;
    }
    removed.destroy();

    let reassign_active_index = this.active_index === index;
    const grandparent_index = removed.parent_index;

    for (let i = index; i < this.local_index; i++) {
      const waypoint = this.waypoints[i];
      if (!waypoint || waypoint._destroy) continue;
      const parent_index = waypoint.parent_index;
      if (parent_index === index) {
        waypoint.setParentIndex(grandparent_index);
        if (grandparent_index !== null && grandparent_index !== undefined) {
          waypoint.setPath();
        } else if (waypoint.path) {
          waypoint.path.setMap(null);
        }
      }
      if (reassign_active_index) {
        this.activateWaypoint(i);
        reassign_active_index = false;
      }
    }

    if (reassign_active_index) {
      if (grandparent_index !== null && grandparent_index !== undefined) {
        this.activateWaypoint(grandparent_index);
      } else {
        this.active_index = null;
        for (let i = this.local_index - 1; i >= 1; i--) {
          if (this.waypoints[i] && !this.waypoints[i]._destroy) {
            this.activateWaypoint(i);
            break;
          }
        }
      }
    }

    this.computeDistances();
  },

  getWaypoint(index) {
    return this.waypoints[index];
  },

  activeWaypoint() {
    return this.waypoints[this.active_index];
  },

  computeDistances() {
    let distance = 0;
    let height_gain = 0;
    let height_loss = 0;
    for (let i = 0; i < this.local_index; i++) {
      const waypoint = this.waypoints[i];
      if (!waypoint || waypoint._destroy) continue;
      waypoint.computeDistance();
      waypoint.setHeightChange();
      distance += waypoint.distToParent();
      const heightChange = waypoint.getHeightChangeToParent();
      if (heightChange >= 0) {
        height_gain += heightChange;
      } else {
        height_loss -= heightChange;
      }
    }
    $("#route_distance").val(Math.round(distance * 100) / 100);
    $("#route_height_gain").val(height_gain);
    $("#route_height_loss").val(height_loss);
  }
};

window.Route = RouteObject;
