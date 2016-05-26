var viridis = ["#440154", "#481567", "#482677", "#453781", "#404788",
               "#39568C", "#33638D", "#2D708E", "#287D8E", "#238A8D",
               "#1F968B", "#20A387", "#29AF7F", "#3CBB75", "#55C667",
               "#73D055", "#95D840", "#B8DE29", "#DCE319", "#FDE725"];
var magma = ["#000004", "#08061D", "#160F3A", "#29115B", "#400F73",
             "#56147D", "#6B1C81", "#802582", "#952C80", "#AB337C",
             "#C13A76", "#D6446D", "#E85362", "#F4685C", "#FA815F",
             "#FD9A6A", "#FEB37B", "#FECC8F", "#FDE4A6", "#FCFDBF"];
var inferno = ["#000004", "#08061E", "#190C3E", "#2F0A5B",
               "#460B69", "#5C126E", "#711A6E", "#87216B", "#9C2964",
               "#B1325B", "#C53C4E", "#D64A40", "#E55C30", "#F0701F",
               "#F8870E", "#FC9F07", "#FBB91E", "#F7D440", "#F1ED6F",
               "#FCA4"];
var plasma = ["#0D0887", "#2D0594", "#44039E",
              "#5A01A5", "#6F00A8", "#8305A7", "#9612A1", "#A72197",
              "#B7308B", "#C53F7E", "#D14E72", "#DD5E66", "#E76E5B",
              "#EF7E4F", "#F69044", "#FBA238", "#FEB62D", "#FDCB26",
              "#F8E225", "#F0F921"];

var categories_en = ["Good (0-50)", "Regular (51-100)",
                  "Bad (101-150)", "Very Bad (151-200)",
                  "Ext. Bad (>200)"];
var categories_es = ["Buena (0-50)", "Regular (51-100)",
                  "Mala (101-150)", "Muy Mala (151-200)",
                  "Ext. Mala (>200)"];
var viridis_st_colors = ["#440154", "#3B528B",
                         "#21908C", "#5DC963",
                         "#FDE725"];
var magma_st_colors = ["#000004", "#50127C",
                       "#B63779", "#FB8761", "#FCFDBF"];
var inferno_st_colors = ["#000004", "#57106D",
                         "#BB3755", "#F98D0A", "#FCFFA4"];
var plasma_st_colors = ["#0D0887", "#7E03A8",
                        "#CB4778", "#F89441", "#F0F921"];
var monthNames_en = [
    "January", "February", "March",
    "April", "May", "June", "July",
    "August", "September", "October",
    "November", "December"
];
var monthNames_es = [
    "Enero", "Febrero", "Marzo",
    "Abril", "Mayo", "Junio", "Julio",
    "Agosto", "Septiembre", "Octubre",
    "Noviembre", "Diciembre"
];
var color_scale = d3.scale.quantize()
        .domain([0,200])
        .range(plasma);
// number of pixels per side, set in heatmap.r
var pixels = 100;
var gridx, gridy;

//var points = data; // data loaded from data.js
L.mapbox.accessToken = 'pk.eyJ1IjoiZGllZ292YWxsZSIsImEiOiJjaW8yeHp5OGgxYXMxdTZseTU4cXMyd3FvIn0.uOJ49T1_d6zDjKebAQDl2w';
var leafletMap = L.map('map').setView([19.48, -99.1], 10);
L.mapbox.styleLayer('mapbox://styles/mapbox/light-v9').
    addTo(leafletMap);

var hash = new L.Hash(leafletMap);

pip = function (point, vs) {
    // ray-casting algorithm based on
    // http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html

    var x = point[0], y = point[1];

    var inside = false;
    for (var i = 0, j = vs.length - 1; i < vs.length; j = i++) {
        var xi = vs[i][0], yi = vs[i][1];
        var xj = vs[j][0], yj = vs[j][1];

        var intersect = ((yi > y) != (yj > y))
                && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
        if (intersect) inside = !inside;
    }

    return inside;
};

d3.json("/data/heatmap_data.json", function(error, data) {
    d3.json("/data/heatmap_stations.json", function(error, stations) {

        var legend = L.control({position: 'bottomright'});
        legend.onAdd = function (map) {

            var div = L.DomUtil.create('div', 'info legend');

            d_str = stations[1].datetime
            var d = new Date(d_str.substr(0, 4), d_str.substr(5, 2), d_str.substr(8, 2), d_str.substr(11, 2), d_str.substr(14, 2), d_str.substr(17, 2));
            var day = d.getDate();
            var monthIndex = d.getMonth();
            var year = d.getFullYear();
            var hours = d.getHours();
            if(lang === 'en')
                div.innerHTML = '<h2>IMECA</h2>' +
                'Value: <span ' +
                'id="mousemove"></span><br><span style="">' +
                monthNames_en[monthIndex-1] + ' ' + day + ', ' + hours + 'h </span><br>';
            else
                div.innerHTML = '<h2>IMECA</h2>' +
                'Índice: <span ' +
                'id="mousemove"></span><br><em>' +
                hours + 'h, ' + day + ' de ' + monthNames_es[monthIndex-1] + ' ' +'</em><br>';
            var categories = lang === "en" ? categories_en : categories_es;
            for (var i = 0; i < categories.length; i++) {
                div.innerHTML +=
                    '<i style="background:' + plasma_st_colors[i] + '"></i> ' +
                    categories[i]  + '<br>';
            }

            return div;
        }

        legend.addTo(leafletMap);
        L.canvasOverlay()
            .drawing(drawingOnCanvas)
            .addTo(leafletMap);

        L.control.locate({
            drawCircle: false,
            strings: {
                title: "Show me where I am",  // title of the locate control
                metersUnit: "meters", // string for metric units
                feetUnit: "feet", // string for imperial units
                popup: "You are within {distance} {unit} from this point",  // text to appear if user clicks on circle
                outsideMapBoundsMsg: "You seem located outside the boundaries of the map" // default message for onLocationOutsideMapBounds
            },
        }).addTo(leafletMap);

        for (var i = 0; i < stations.length; i++) {
            var c = L.circle([stations[i]["lat"], stations[i]["lon"]],
                             550);
            var rectangle = new L.Rectangle(c.getBounds(), {
                color: "black",
                fillColor: color_scale(stations[i].value),
                fillOpacity: 0.25,
                lineCap: "square",
                lineJoin: "miter"
            });
            rectangle.bindPopup(String(stations[i].station_name + ': <b>' +
                                       stations[i].value + '</b> (' +
                                       stations[i].pollutant +')'), {
                                           offset: L.point(0, -2),
                                           autoPan: false
                                       })
                .addTo(leafletMap);
            rectangle.on('mouseover', function (e) {
                this.openPopup();
            });
            rectangle.on('mouseout', function (e) {
                this.closePopup();
            });
        }



        function drawingOnCanvas(canvasOverlay, params) {
            var ctx = params.canvas.getContext('2d');
            ctx.clearRect(0, 0, params.canvas.width, params.canvas.height);
            /*
             The latitude of Mexico City, Federal District, Mexico is
             19.432608 (x), and the longitude (y )is -99.133209
             The variable data holds an array with Mexico City divided into
             10,000 cells like this:

             [[pollution_value, longitude, latitude],...]

            The lng and lat refer to the center of the cell
             */
            var cell_width = data[0][2] - data[pixels][2];
            var cell_height = data[0][1] - data[1][1];
            var upper_left, lower_right, width, height;
            for (var i = 0; i < data.length; i++) {
                var d = data[i];
                upper_left = canvasOverlay.
                    _map.
                    latLngToContainerPoint([d[2] - cell_width / 2,
                                            d[1] - cell_height / 2]);
                lower_right = canvasOverlay._map
                    .latLngToContainerPoint([d[2] + cell_width / 2,
                                             d[1] + cell_height / 2]);
                ctx.beginPath();
                /*
                 Unlike the data, the canvas rect method uses the x
                 upper-left corner, the y upper-left corner, and the
                 width and height
                 */
                width = upper_left.x - lower_right.x;
                height = upper_left.y - lower_right.y;
                ctx.rect(upper_left.x,
                         upper_left.y,
                         width,
                         height);
                ctx.fillStyle = color_scale(d[0]);
                ctx.fill();
                // add a stroke style and width to avoid blank lines between
                // cells
                ctx.strokeStyle = color_scale(d[0]);
                ctx.lineWidth = 4;
                ctx.stroke();
            }
        };

        leafletMap.on('mousemove click', function(e) {
            var cell_width = data[1][2] - data[pixels + 1][2];
            var cell_height = data[1][1] - data[2][1];
            var ulx, uly, lrx, lry;
            for (var i = 0; i < data.length; i++) {
                var d = data[i];

                ulx = d[2] - cell_width / 2;
                uly = d[1] - cell_height / 2;
                lrx = d[2] + cell_width / 2;
                lry = d[1] + cell_height / 2;
                isin = pip([e.latlng.lat, e.latlng.lng], [
                    [ulx, uly],
                    [lrx, uly],
                    [lrx, lry],
                    [ulx, lry]
                ]);
                if (isin) {
                    window['mousemove'].innerHTML = Math.round(d[0]);
                    break;
                }
            }

        });


    });
});
