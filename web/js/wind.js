var categories_en = ['Calm', 'Gentle Breeze',
                     'Strong Breeze', 'Strong Gale',
                     'Hurricane Force'];
var categories_es = ['Calma', 'Brisa Ligera',
                     'Brisa Fuerte', 'Temporal fuerte',
                     'Huracán'];
var viridis_st_colors = ['#440154', '#3B528B',
                         '#21908C', '#5DC963',
                         '#FDE725'];
var magma_st_colors = ['#000004', '#50127C',
                       '#B63779', '#FB8761', '#FCFDBF'];
var inferno_st_colors = ['#000004', '#57106D',
                         '#BB3755', '#F98D0A', '#FCFFA4'];
var plasma_st_colors = ['#0D0887', '#7E03A8',
                        '#CB4778', '#F89441', '#F0F921'];
var monthNames_en = [
    'January', 'February', 'March',
    'April', 'May', 'June', 'July',
    'August', 'September', 'October',
    'November', 'December'
];
var monthNames_es = [
    'Enero', 'Febrero', 'Marzo',
    'Abril', 'Mayo', 'Junio', 'Julio',
    'Agosto', 'Septiembre', 'Octubre',
    'Noviembre', 'Diciembre'
];

var viridis = ['#440154', '#481567', '#482677', '#453781', '#404788',
               '#39568C', '#33638D', '#2D708E', '#287D8E', '#238A8D',
               '#1F968B', '#20A387', '#29AF7F', '#3CBB75', '#55C667',
               '#73D055', '#95D840', '#B8DE29', '#DCE319', '#FDE725'];
var magma = ['#000004', '#08061D', '#160F3A', '#29115B', '#400F73',
             '#56147D', '#6B1C81', '#802582', '#952C80', '#AB337C',
             '#C13A76', '#D6446D', '#E85362', '#F4685C', '#FA815F',
             '#FD9A6A', '#FEB37B', '#FECC8F', '#FDE4A6', '#FCFDBF'];
var inferno = ['#000004', '#08061E', '#190C3E', '#2F0A5B',
               '#460B69', '#5C126E', '#711A6E', '#87216B', '#9C2964',
               '#B1325B', '#C53C4E', '#D64A40', '#E55C30', '#F0701F',
               '#F8870E', '#FC9F07', '#FBB91E', '#F7D440', '#F1ED6F',
               '#FCA4'];
var plasma = ['#0D0887', '#2D0594', '#44039E',
              '#5A01A5', '#6F00A8', '#8305A7', '#9612A1', '#A72197',
              '#B7308B', '#C53F7E', '#D14E72', '#DD5E66', '#E76E5B',
              '#EF7E4F', '#F69044', '#FBA238', '#FEB62D', '#FDCB26',
              '#F8E225', '#F0F921'];
var color_scale = d3.scale.quantize()
        .domain([0, 32])
        .range(plasma);
// number of pixels per side, set in heatmap.r
var pixels = 100;
var gridx, gridy;
var canvasOverlay, tree;
var requestId;
var num_particles = 3000;
var particles;
var tree;
// length of particle movement in degrees
var particle_len = 0.000259248 * 1;
// line width of each particle
var lineWidth = 2;
// Maximum age of the particle before generating a new one
var MaxAge = 40;
var ctx;


// http://paulirish.com/2011/requestanimationframe-for-smart-animating/
// http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating

// requestAnimationFrame polyfill by Erik MÃ¶ller. fixes from Paul Irish and Tino Zijdel

// MIT license

(function() {
    var lastTime = 0;
    var vendors = ['ms', 'moz', 'webkit', 'o'];
    for (var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
        window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
        window.cancelAnimationFrame = window[vendors[x]+'CancelAnimationFrame']
            || window[vendors[x]+'CancelRequestAnimationFrame'];
    }

    if (!window.requestAnimationFrame)
        window.requestAnimationFrame = function(callback, element) {
            var currTime = new Date().getTime();
            var timeToCall = Math.max(0, 16 - (currTime - lastTime));
            var id = window.setTimeout(function() { callback(currTime + timeToCall); },
                                       timeToCall);
            lastTime = currTime + timeToCall;
            return id;
        };

    if (!window.cancelAnimationFrame)
        window.cancelAnimationFrame = function(id) {
            clearTimeout(id);
        };
}());



//var points = data; // data loaded from data.js
var leafletMap = L.map('map').setView([19.48, -99.1], 10);
L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="http://cartodb.com/attributions">CartoDB</a>',
    subdomains: 'abcd',
    maxZoom: 19
}).addTo(leafletMap);


var hash = new L.Hash(leafletMap);

pip = function(point, vs) {
    // ray-casting algorithm based on
    // http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html

    var x = point[0], y = point[1];

    var inside = false;
    for (var i = 0, j = vs.length - 1; i < vs.length; j = i++) {
        var xi = vs[i][0], yi = vs[i][1];
        var xj = vs[j][0], yj = vs[j][1];

        var intersect = ((yi > y) != (yj > y)) &&
                (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
        if (intersect) inside = !inside;
    }

    return inside;
};

function Particle(canvasOverlay, cell_data,
                  canvas_width, canvas_height) {
    this.canvasOverlay = canvasOverlay;
    this.left_x = cell_data[0][1];
    this.right_x = cell_data[Math.sqrt(cell_data.length) - 1][1];
    this.top_y = cell_data[0][2];
    this.bottom_y = cell_data[cell_data.length - 1][2];

    var coords = get_random_coords(this.canvasOverlay, this.left_x,
                                   this.right_x, this.top_y, this.bottom_y);
    this.start_x = coords[0];
    this.start_y = coords[1];
    this.start_x_lat = coords[4];
    this.start_y_lng = coords[5];
    this.end_x = coords[2];
    this.end_y = coords[3];
    this.end_x_lat = coords[6];
    this.end_y_lng = coords[7];
    this.wsp = coords[8];
    this.canvas_width = canvas_width;
    this.canvas_height = canvas_height;
    this.count = 0;
};

Particle.prototype.move = function() {
    this.start_x = this.end_x;
    this.start_y = this.end_y;
    this.start_x_lat = this.end_x_lat;
    this.start_y_lng = this.end_y_lng;
    end = get_end_coords(this.canvasOverlay,
                         this.start_x_lat, this.start_y_lng);
    canvas_rect = [[this.left_x, this.top_y],
                   [this.left_x, this.bottom_y],
                   [this.right_x, this.bottom_y],
                   [this.right_x, this.top_y]];
    //if(end[0] === -1 | this.count > 30 |
    //   !pip([this.start_y_lng, this.start_x_lat], canvas_rect)) {
    if (end[0] === -1 | (Math.random() < .04 & this.count > MaxAge) |
       !pip([this.start_y_lng, this.start_x_lat], canvas_rect)) {
        var coords = get_random_coords(this.canvasOverlay, this.left_x,
                                       this.right_x, this.top_y, this.bottom_y);
        this.start_x = coords[0];
        this.start_y = coords[1];
        this.start_x_lat = coords[4];
        this.start_y_lng = coords[5];
        this.end_x = coords[2];
        this.end_y = coords[3];
        this.end_x_lat = coords[6];
        this.end_y_lng = coords[7];
        this.wsp = coords[8];
        //this.canvas_width = canvas_width;
        //this.canvas_height = canvas_height;
        this.count = 0;
    } else {
        this.end_x = end[0];
        this.end_y = end[1];
        this.end_x_lat = end[2];
        this.end_y_lng = end[3];
        this.wsp = end[4];
        this.count += 1;
    }
};

Particle.prototype.draw = function(ctx) {
    ctx.beginPath();
    canvas_line(ctx, this.start_x, this.start_y,
                this.end_x, this.end_y, 'black');
    ctx.stroke();
};

function canvas_line(context, fromx, fromy, tox, toy, color) {
    context.strokeStyle = color;
    context.lineWidth = lineWidth;
    context.moveTo(fromx, fromy);
    context.lineTo(tox, toy);
}

function get_random_coords(canvasOverlay, left_x, right_x, top_y, bottom_y) {
    var d = [0,
             random_range(left_x, right_x),
             random_range(top_y, bottom_y)];
    var wind_vec = tree.search([d[1], d[2], d[1], d[2]]);
    if (wind_vec.length == 0)
        return ([-1, -1, -1, -1, -1, -1, -1, -1]);

    var start = canvasOverlay._map.latLngToContainerPoint([d[2],
                                                           d[1]]);

    var comp = components(wind_vec[0][4].wdr,
                          (wind_vec[0][4].wsp) * particle_len);
    var end = canvasOverlay.
            _map.
            latLngToContainerPoint([d[2] - comp[1],
                                    d[1] + comp[0]]);
    return ([start.x, start.y, end.x, end.y,
             d[2], d[1],
             d[2] - comp[1], d[1] - comp[0],
             wind_vec[0][4].wsp]);
}

function get_end_coords(canvasOverlay, start_x_lat, start_y_lng) {
    var wind_vec = tree.search([start_y_lng, start_x_lat,
                                start_y_lng, start_x_lat]);
    if (wind_vec.length == 0)
        return ([-1, -1, -1, -1, -1, -1, -1, -1]);
    var comp = components(wind_vec[0][4].wdr,
                          (wind_vec[0][4].wsp) * particle_len);
    var end = canvasOverlay.
            _map.
            latLngToContainerPoint([start_x_lat - comp[1],
                                    start_y_lng + comp[0]]);
    return ([end.x, end.y, start_x_lat + comp[1],
            start_y_lng + comp[0], wind_vec[0][4].wsp]);
}

function random_range(min, max) {
    return Math.random() * (max - min) + min;
}

// Wind direction:
// https://compuweather.com/files/2009/10/CompuWeather-Wind-Direction-Compass-Chart.pdf
function components(direction, speed) {
    var theta = direction / 360 * Math.PI * 2;
    var u = -speed * Math.sin(theta);
    var v = -speed * Math.cos(theta);
    return [u, v];
}

d3.json('/data/wdr_data.json', function(error, data) {
    d3.json('/data/wsp_data.json', function(error, wsp) {
        d3.json('/data/wsp_stations.json', function(error, stations) {
            var legend = L.control({position: 'bottomright'});
            legend.onAdd = function(map) {

                var div = L.DomUtil.create('div', 'info legend');

                d_str = stations[1].datetime_mxc;
                d = moment(d_str, 'YYYY-MM-DD %H:%m:%s');
                if (lang === 'en') {
                    d.locale(lang);
                    div.innerHTML = 'Wind Speed: <span ' +
                        'id="mousemove"></span><br><span style="">' +
                        d.format('MMM DD, H:mm') +
                        //monthNames_en[monthIndex - 1] + ' ' + day + ', ' + hours +
                        'h </span><br>';
                }
                else {
                    d.locale(lang);
                    div.innerHTML = 'Velocidad: <span ' +
                        'id="mousemove"></span><br><em>' +
                        d.format('H:mm[h], DD[ de ]MMM') +
                        '</em><br>';
                }
                categories = lang === 'en' ? categories_en : categories_es;
                for (var i = 0; i < categories.length; i++) {
                    div.innerHTML +=
                        '<i style="background:' + plasma_st_colors[i] +
                        '"></i> ' +
                        categories[i] + '<br>';
                }

                return div;
            };

            // width and height of each cell
            height = data[1][2] - data[pixels + 1][2];
            width = data[1][1] - data[2][1];
            // fill the R-tree with all the wind cells
            var squares = [];
            for (var i = 0; i < data.length; i++) {
                var d = data[i];
                squares.push([
                    // latitudes are negative so we have to add to get the
                    // lower left corner
                    d[1] + width / 2,
                    d[2] - height / 2,
                    // upper right corner
                    d[1] - width / 2,
                    d[2] + height / 2,
                    {
                        wdr: d[0],
                        wsp: wsp[i][0]
                    }]);
            }
            tree = rbush(2);
            tree.load(squares);

            // for (var j = 0; j < 150; j++) {
            //     console.log(j)
            //     tree = rbush(j)
            //     tree.load(squares);
            //     console.time('tree');
            //     for (var i = 0; i < 10000; i++)
            //         tree.search([-99.34973279877691, 19.374493310358307, -99.34973279877691, 19.374493310358307]);
            //     console.timeEnd('tree');
            // }

            legend.addTo(leafletMap);
            L.canvasOverlay()
                .drawing(drawingOnCanvas)
                .addTo(leafletMap);

            L.control.locate({
                drawCircle: false,
                strings: {
                    title: 'Show me where I am',  // title of the locate control
                    metersUnit: 'meters', // string for metric units
                    feetUnit: 'feet', // string for imperial units
                    popup: 'You are within {distance} {unit} from this point',  // text to appear if user clicks on circle
                    outsideMapBoundsMsg: 'You seem located outside the boundaries of the map' // default message for onLocationOutsideMapBounds
                }
            }).addTo(leafletMap);

            // build an r tree for fast searching the wind speed and direction
            for (var i = 0; i < stations.length; i++) {
                var c = L.circle([stations[i]['lat'], stations[i]['lon']],
                                 550);
                var rectangle = new L.Rectangle(c.getBounds(), {
                    color: 'black',
                    fillColor: color_scale(stations[i].value),
                    fillOpacity: 0.25,
                    lineCap: 'square',
                    lineJoin: 'miter'
                });
                rectangle.bindPopup(String(stations[i].station_name + ': <b>' +
                                           stations[i].value + '</b> m/s'), {
                                               offset: L.point(0, -2),
                                               autoPan: false
                                           })
                    .addTo(leafletMap);
                rectangle.on('mouseover', function(e) {
                    this.openPopup();
                });
                rectangle.on('mouseout', function(e) {
                    this.closePopup();
                });
            }


            function loop() {
                var prev = ctx.globalCompositeOperation;
                ctx.fillStyle = 'rgba(0,0,0, 0.80)';
                ctx.globalCompositeOperation = 'destination-in';
                ctx.fillRect(0, 0, canvas_width, canvas_height);
                ctx.globalCompositeOperation = prev;
                // console.time('draw particles');
                particles.forEach(function(particle, i) {
                    particle.draw(ctx);
                    particle.move();
                });
                // console.timeEnd('draw particles');

                requestId = window.requestAnimationFrame(loop, ctx);
            }

            function start() {
                if (!requestId) {
                    loop();
                }
            }

            function stop() {
                if (requestId) {
                    window.cancelAnimationFrame(requestId);
                    requestId = undefined;
                }
            }

            function drawingOnCanvas(canvasOverlay, params) {
                ctx = params.canvas.getContext('2d');
                ctx.clearRect(0, 0, params.canvas.width, params.canvas.height);
                canvas_width = params.canvas.width;
                canvas_height = params.canvas.height;


                particles = new Array(num_particles);

                for (var i = 0; i < num_particles; i++) {
                    particles[i] = new Particle(canvasOverlay, data,
                                                canvas_width, canvas_height);
                }

                stop();
                start();

            };

            leafletMap.on('zoomstart', function(e) { stop(); });
            leafletMap.on('zoomend', function(e) { start(); });
            leafletMap.on('mousedown', function(e) { stop(); });
            leafletMap.on('mouseup', function(e) { start(); });

            leafletMap.on('mousemove click', function(e) {
                gridx = data[1][2] - data[pixels + 1][2];
                gridy = data[1][1] - data[2][1];
                for (var i = 0; i < data.length; i++) {
                    var d = data[i];

                    ulx = d[2] - gridx / 2;
                    uly = d[1] - gridy / 2;
                    wx = d[2] + gridx / 2;
                    wy = d[1] + gridy / 2;
                    isin = pip([e.latlng.lat, e.latlng.lng], [
                        [ulx, uly],
                        [wx, uly],
                        [wx, wy],
                        [ulx, wy]
                    ]);
                    if (isin) {
                        window['mousemove'].innerHTML = Math.round(wsp[i][0]) +
                            ' m/s';
                        break;
                    } else {
                        //window[e.type].innerHTML = '';
                    }
                }

            });
        });
    });
});
