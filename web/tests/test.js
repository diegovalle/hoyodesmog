var partialURL = 'http://localhost:8000';
var i;
var errors = [];

casper.test.begin(
    'Visit hoyodesmog pages and check for errors',
    1,
    function suite(test) {
        casper.start(partialURL, function() {
            this.wait(150000, function() {
                test.assertTitle('Real-Time Mexico City Air Quality Index',
                                 'homepage title is the one expected');
                test.assertExists('svg g path', 'station square exists');
                test.assertExists('canvas', 'canvas exists');
                test.assertExists('img.leaflet-tile-loaded', 'map tiles exist');
            });
        });

        casper.thenOpen(partialURL + '/es/index.html', function() {
            this.wait(150000, function() {
                test.assertExists('svg g path', 'station square exists');
                test.assertExists('canvas', 'canvas exists');
                test.assertExists('img.leaflet-tile-loaded', 'map tiles exist');
            });
        });

        casper.thenOpen(partialURL + '/es/temperature.html', function() {
            this.wait(150000, function() {
                test.assertExists('svg g path', 'station square exists');
                test.assertExists('canvas', 'canvas exists');
                test.assertExists('img.leaflet-tile-loaded', 'map tiles exist');
            });
        });

        casper.thenOpen(partialURL + '/temperature.html', function() {
            this.wait(150000, function() {
                test.assertExists('svg g path', 'station square exists');
                test.assertExists('canvas', 'canvas exists');
                test.assertExists('img.leaflet-tile-loaded', 'map tiles exist');
            });
        });

        casper.thenOpen(partialURL + '/wind.html', function() {
            this.wait(150000, function() {
                test.assertExists('svg g path', 'station square exists');
                test.assertExists('canvas', 'canvas exists');
                test.assertExists('img.leaflet-tile',
                                  'en wind map tiles exist');
            });
        });

        casper.thenOpen(partialURL + '/es/wind.html', function() {
            this.wait(150000, function() {
                test.assertExists('svg g path', 'station square exists');
                test.assertExists('canvas', 'canvas exists');
                test.assertExists('img.leaflet-tile-loaded',
                                  'es wind map tiles exist');
            });
        });



        casper.thenOpen(partialURL + '/es/ozone.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
                test.assertEval(function() {
                    return __utils__
                        .findAll('div.line-chart svg path').length >= 10;
                }, 'should have lots of charts');
            });
        });
        casper.thenOpen(partialURL + '/ozone.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
                test.assertEval(function() {
                    return __utils__
                        .findAll('div.line-chart svg path').length >= 10;
                }, 'should have lots of charts');
            });
        });

        casper.thenOpen(partialURL + '/es/pm10.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });
        casper.thenOpen(partialURL + '/pm10.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });

        casper.thenOpen(partialURL + '/es/so2.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });
        casper.thenOpen(partialURL + '/so2.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });

        casper.thenOpen(partialURL + '/es/no2.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });
        casper.thenOpen(partialURL + '/no2.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });

        casper.thenOpen(partialURL + '/es/co.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });
        casper.thenOpen(partialURL + '/co.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });

        casper.thenOpen(partialURL + '/es/nox.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });
        casper.thenOpen(partialURL + '/nox.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });

        casper.thenOpen(partialURL + '/es/pm25.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });
        casper.thenOpen(partialURL + '/pm25.html', function() {
            this.wait(150000, function() {
                test.assertExists('div.line-chart svg path',
                                  'small multiple line chart exists');
            });
        });

        casper.thenOpen(partialURL + '/es/about.html');
        casper.thenOpen(partialURL + '/about.html');

        casper.on('page.error', function(msg, trace) {
            this.echo('Error:    ' + msg, 'ERROR');
            this.echo('file:     ' + trace[0].file, 'WARNING');
            this.echo('line:     ' + trace[0].line, 'WARNING');
            this.echo('function: ' + trace[0]['function'], 'WARNING');
            errors.push(msg);
            test.fail('console error');
        });

        casper.on('resource.received', function(resource) {
            var status = resource.status;
            if (status >= 400) {
                test.fail('resource failed to load');
                casper.log('Resource ' + resource.url +
                           ' failed to load (' + status + ')', 'error');

                errors.push({
                    url: resource.url,
                    status: resource.status
                });
            }
        });

        casper.run(function() {
            if (errors.length > 0) {
                this.echo(errors.length +
                          'errors found', 'WARNING');
            } else {
                this.echo(errors.length + ' Javascript errors found', 'INFO');
            }
            casper.exit();
        });
    });
