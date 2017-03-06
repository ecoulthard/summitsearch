var trimble = {
    scriptBaseUrl: null,
    myTopo: {
        partnerID: null,
        hash: null,
        isError: function () {
            return !(this.partnerID && this.hash);
        },
        MapTypeId: {
            Topo: "MyTopoTopoBaseLayer"
        },
        topoBaseLayer: new google.maps.ImageMapType({
            getTileUrl: function (coord, zoom, ownerDocument) {
                return "http://tileserver.mytopo.com/SecureTile/TileHandler.ashx?mapType=Topo&partnerID=" + trimble.myTopo.partnerID + "&hash=" + trimble.myTopo.hash + "&x=" + coord.x + "&y=" + coord.y + "&z=" + zoom;
            },
            tileSize: new google.maps.Size(256, 256),
            name: 'MyTopo',
            //alt: 'MyTopo Enhanced Topo Maps',
            maxZoom: 16,
            minZoom: 9
        }),
        map: null,
        //Call this to initialize your map database, so that you can reference map types by ID.
        init: function (map) {
            this.map = map;
            if (this.isError()) {
                alert("[MyTopo]: You must supply both the partnerID and hash in the query string of the trimble.mytopo.js");
            } else {
                map.mapTypes.set(trimble.myTopo.MapTypeId.Topo, trimble.myTopo.topoBaseLayer);
                map.mapTypeControlOptions.mapTypeIds.splice(0, 0, trimble.myTopo.MapTypeId.Topo);
            }

            google.maps.event.addListener(map, 'maptypeid_changed', this.updateCopyright);

            if (this.copyrightDiv == null) {
                // Create div for showing copyrights.
                this.copyrightDiv = document.createElement('div');
                this.copyrightDiv.id = 'mytopo-copyright-control';
                this.copyrightDiv.style.fontSize = '11px';
                this.copyrightDiv.style.fontFamily = 'Arial, sans-serif';
                this.copyrightDiv.style.margin = '0 2px 2px 0';
                this.copyrightDiv.style.whiteSpace = 'nowrap';
                this.copyrightDiv.style.color = '#FF4500';
                this.copyrightDiv.index = 0;
                this.copyrightDiv.innerHTML = trimble.myTopo.getBannerHtml();
            }
            map.controls[google.maps.ControlPosition.BOTTOM_RIGHT].push(this.copyrightDiv);
            this.updateCopyright();
        },
        printMap: function () {
            var lat = trimble.myTopo.map.getCenter().lat();
            var lng = trimble.myTopo.map.getCenter().lng();
            var url = 'http://www.mytopo.com/searchgeo.cfm?lat=' + lat + '&lon=' + lng + '&partnerid=' + trimble.myTopo.partnerID;
            //setup our fancybox
            jQuery.fancybox({
                'width': '803',
                'height': '70%',
                'autoScale': false,
                'transitionIn': 'none',
                'transitionOut': 'none',
                'type': 'iframe',
                'href': url
            });
            return false;
        },
        getBannerHtml: function () {
            switch (trimble.myTopo.partnerID) {
                case 839:
                    return '&#169; MyTopo <a href="http://mytopo.com/about/terms.cfm" target="_blank"><b>(MyTopo Terms of Use)</b></a>';
                    break;
				case 12288:
                    return '&#169; MyTopo <a href="http://mytopo.com/about/terms.cfm" target="_blank"><b>(MyTopo Terms of Use)</b></a>';
                    break;
                //case 49: 
                default:
                    return "<a id='printMyTopoMap' href='#printMap' onclick='return trimble.myTopo.printMap();'><img src='" + trimble.scriptBaseUrl + "../Images/button_print.png' alt='Print MyTopo Map' border='0' /></a>" +
                    "<a href='http://get.it/trimbleoutdoors/8pAD' target='_blank'><img src='" + trimble.scriptBaseUrl + "../Images/button_get.png' id='Get MyTopo App' border='0' /></a>" +
                    "<a href='http://www.mytopo.com/' target='_blank'><img src='" + trimble.scriptBaseUrl + "../Images/SmallMyTopoLogo.png' alt='MyTopo Logo' border='0'/></a><br/>" +
                    "<a href='http://mytopo.com/about/terms.cfm' target='_blank'><b>(MyTopo Terms of Use)</b></a>";

            }
        },
        updateCopyright: function () {
            trimble.myTopo.copyrightDiv.style.display = (trimble.myTopo.map.getMapTypeId() == trimble.myTopo.MapTypeId.Topo) ? "inline" : "none";
        },
        tellDeveloper: function (msg) {
            alert(msg + "\n\nPlease email partner@mytopo.com if you need any assistance getting this setup.");
        },
        copyrightDiv: null
    }
};

{
    trimble.scriptBaseUrl = "http://www.mytopo.com/TileService/Scripts/";
    trimble.myTopo.partnerID = $("#trimble-data").data("partner-id");
    trimble.myTopo.hash = $("#trimble-data").data("hash");
}
