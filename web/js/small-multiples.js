$(document).ready(function() {
    d3.json(stations_file, function(data) {

        // Convert the strings to dates
        for (var i = 0; i < data.length; i++)
            for (var j = 0; j < data[i].length; j++) {
                //for(k =0; k< data[i][j].length; k++)
                d = data[i][j].datetime;
                data[i][j].date = new Date(d.substr(0, 4),
                                           d.substr(5, 2) - 1,
                                           d.substr(8, 2),
                                           d.substr(11, 2),
                                           d.substr(14, 2),
                                           d.substr(17, 2));
            }

        // Create the containers for the line charts of each stations
        for (var i = 0; i < data.length; i++) {
            if (!_.every(data[i], {value: null})) {
                $('<div class=\"4u 12u(mobile)\" >' +
                  '<div class =\"line-chart\" id=\"line' +
                  data[i][0].station_code +
                  '\"></div></div>')
                    .appendTo('#small-multiples');

                MG.data_graphic({
                    title: data[i][0].station_code,
                    description: data[i][0].station_name,
                    show_tooltips: true,
                    show_secondary_x_label: false,
                    data: data[i],
                    //y_extended_ticks: true,
                    yax_count: 3,
                    xax_count: 3,
                    //min_x: new Date("2016-03-27 21:00:00"),
                    // Converting IMECAS to ppb the phase I
                    //value is 155 (150 IMECAS)
                    baselines: baseline, /*,{value: 205, label: 'phase I'}],*/
                    full_width: true,
                    area: false,
                    target: '#line' + data[i][0].station_code,
                    //show_confidence_band: ['lo95', 'hi95'],
                    legend: top_legend,
                    legend_target: '.legend',
                    interpolate: 'linear',
                    x_mouseover: '%Y-%b-%d %H:%M% h — ',
                    left: 70,
                    y_label: y_label
                    //mouseover: function(d, i) {
                    // custom format the rollover text, show days
                    //  var prefix = d3.formatPrefix(d.value);
                    // d3.select('#custom-rollover svg .mg-active-datapoint')
                    //  .text(d.date);
                    //},
                });

            }
        }
    });
});
