// Our constructor for creating border points. Used for both new and loaded border points.
var BorderPoint = window.BorderPoint = class BorderPoint {
  constructor(id, latitude, longitude) {
    this.id = id;
    this.latitude = latitude;
    this.longitude = longitude;
    this._destroy = false;
    this.latLon = new google.maps.LatLng(this.latitude, this.longitude);
    this.marker = new google.maps.Marker({
      position: this.latLon,
      map: window.map,
      title: "A border point",
      draggable: true,
      icon: "/assets/markers/yellow-dot.png"
    });

    // Set parent icon to red if id > 0
    if (this.id > 0 && window.Place && window.Place.borderPoints && window.Place.borderPoints[this.id - 1]) {
      window.Place.borderPoints[this.id - 1].marker.setIcon();
    }

    // Make sure local_index value is equal to the index used by Place
    $(`#place_border_points_attributes_${this.id}_local_index`).val(this.id);
    const index = this.id;

    // Remove marker when right clicked
    google.maps.event.addListener(this.marker, 'rightclick', () => {
      window.Place.removeBorderPoint(index);
    });

    // Change the border point lat/lon to the new coordinate for the marker
    google.maps.event.addListener(this.marker, 'dragend', (event) => {
      window.Place.moveBorderPoint(index, event.latLng.lat(), event.latLng.lng());
    });
  }

  destroy() {
    this.marker.setMap(null);
    this.setDestroy(true);
  }

  setPosition(newLatitude, newLongitude) {
    const latLng = new google.maps.LatLng(newLatitude, newLongitude);
    if (google.maps.geometry.spherical.computeDistanceBetween(this.marker.getPosition(), latLng) > 100000) {
      alert("Border points cannot be moved by more than 100km apart.");
      return;
    }
    this.latitude = newLatitude;
    this.longitude = newLongitude;
    $(`#place_border_points_attributes_${this.id}_latitude`).val(newLatitude);
    $(`#place_border_points_attributes_${this.id}_longitude`).val(newLongitude);
    this.latLon = latLng;
    this.marker.setPosition(this.latLon);
  }

  setDestroy(newDestroy) {
    this._destroy = newDestroy;
    $(`#place_border_points_attributes_${this.id}__destroy`).val(newDestroy);
  }
}

window.BorderPoint = BorderPoint;
