/**
 * Grapher javascript
 *
 * This program is open source, licensed under the PostgreSQL License.
 * For license terms, see the LICENSE file.
 *
 * Copyright (C) 2012-2014: Open PostgreSQL Monitoring Development Group
**/

(function($) {

    var Grapher = function (element, options) {
        this.config = options;
        this.$element = $(element);
        this.legend_box = this.config.legend_box ||
            $('<div class="legend" />');

        this.$element.append('<div class="plot">');
        this.legend_box
            .data('id-graph', this.$element.attr('id-graph'));

        if (! this.config.legend_box) {
            this.$element.append(this.legend_box);
        }

        this.default_props = {
            autoscale: true,
            bars: {
              barWidth: 1,
              filled: true,
              grouped: false,
              lineWidth: 2,
              stacked: false
            },
            HtmlText: false,
            legend: {
              position: 'ne',
              show: false,
              backgroundColor: '#121212'
            },
            lines: {
              filled: true,
              lineWidth: 2,
              stacked: false,
              fillOpacity: 0.4
            },
            mouse: {
                 track: true,
                 sensibility: 5,
                 trackFormatter: function (o) {
                     var d = new Date(parseInt(o.x, 10));
                     return d.toString() +"<br />"+ o.series.label +' = '+ $().formatUnit(o.series.data[o.index][1], o.series.yaxis.options.unit);
                 },
            },
            pie: {
              filled: true,
              lineWidth: 2
            },
            points: {
              filled: true,
              lineWidth: 2,
              radius: 3
            },
            selection: {
                mode : 'x',
                fps : 30
            },
            shadowSize: 0,
            type: 'line',
            xaxis: {
                autoscale: false,
                autoscaleMargin: 5,
                labelsAngle: 0,
                mode: 'time',
                showLabels: true,
                timeFormat: '%d/%m/%y %H:%M:%S',
                timeMode: 'local',
                titleAngle: 0
            },
            yaxis: {
                autoscale: true,
                autoscaleMargin: 5,
                labelsAngle: 0,
                showLabels: true,
                titleAngle: 90,
                tickFormatter: function (val) { return $().formatUnit (val, this.unit); }
            },
            grid: {
              color: '#bbbbbb',
              backgroundColor: '#232323'
            }
        };
    };

    Grapher.prototype = {

        constructor: Grapher,

        html_error: function (message) {
            if (message === undefined) { message = ''; }

            return '<div class="alert alert-error">'+
                '<button type="button" class="close" data-dismiss="alert">&times;</button>'+
                '<strong>Error:</strong> '+ message +
                '</div>';
        },

        fetch_data: function (url, fromDate, toDate, callback) {

            var grapher = this,
                post_data, a;

            if (fromDate === undefined) { fromDate = this.config.from; }

            if (toDate === undefined)   { toDate = this.config.to; }

            post_data = {
                id: this.config.id,
                from: fromDate,
                to: toDate
            };

            a = $.ajax(url, {
                type: 'post',
                url: url,
                dataType: 'json',
                data: post_data,
            }).done(function(r){
                grapher.fetched = r;
                if ( r.error === undefined ) {
                    grapher.fetched.properties = $.extend(true,
                        grapher.default_props,
                        grapher.fetched.properties || {}
                        );
                }
                if(callback){
                    callback();
                }
            });
        },

        draw: function () {
            var $plot   = this.$element.find('.plot'),
                $legend = this.legend_box,
                inactiveSeries = null,
                self = this;
            // Empty the graph to draw it from scratch
            $legend.empty();

            // Remember active series if we already have some
            if (this.fetched && this.fetched.series.length) {
                inactiveSeries = [];
                $.map(this.fetched.series, function (s) {
                    if (s.hide) { inactiveSeries.push(s.label); }
                });
            }

            // Fetch to data to plot
            this.fetch_data(this.config.url, undefined, undefined, function(){
                if (self.fetched.error !== undefined) {
                    if (self.fetched.redirect === 1) {
                        document.location = document.location;
                    }
                    else {
                        $plot.parent().empty()
                            .append(self.html_error(self.fetched.error));
                    }
                    return false;
                }

                if (inactiveSeries !== null) {
                    $.map(self.fetched.series, function (s) {
                        if (inactiveSeries.indexOf(s.label) !== -1) {
                            s.hide = true;
                        }
                    });
                }

                self.refresh();
                self.drawLegend();
            });
        },

        refresh: function () {
            var properties = this.fetched.properties,
                series     = this.fetched.series,
                container  = this.$element.find('.plot').get(0);

            this.$element.find('.plot').unbind().empty();

            // Draw the graph
            this.flotr = Flotr.draw(container, series, properties);
        },

        _activateSerie: function($e) {
            $e.find('.flotr-legend-color-box')
                .css('opacity', 0.9);
            $e.find('label')
                .removeClass('deactivated');
        },

        _deactivateSerie: function($e) {
            $e.find('.flotr-legend-color-box')
                .css('opacity', 0.1);
            $e.find('label')
                .addClass('deactivated');
        },

        drawLegend: function() {

            var $legend    = this.legend_box,
                legend_opt = this.flotr.legend.options,
                series     = this.flotr.series,
                self       = this,
                i, label, $label, color, s, $cell, toggleSerie,
                itemCount  = $.grep(series, function (e) {
                        return (e.label && !e.hide);
                    }).length;

            if (itemCount) {
                toggleSerie = function () {
                    var $this = $(this),
                        serie = self.fetched.series[$this.data('i')];
                    serie.hide = ! serie.hide;
                    if ( serie.hide ) {
                        self._deactivateSerie($this);
                    }
                    else { self._activateSerie($this); }
                    self.refresh();
                };
                for(i = 0; i < series.length; ++i) {
                    if(!series[i].label) { continue; }

                    s = series[i];

                    label = legend_opt.labelFormatter(s.label);
                    color = ((s.bars && s.bars.show && s.bars.fillColor && s.bars.fill) ? s.bars.fillColor : s.color);

                    $cell = $('<span>').addClass('flotr-legend-color-box')
                            .css({
                                'margin' : '0 10px 0 0',
                                'display': 'inline-block',
                                'border' : '1px solid '+ legend_opt.labelBoxBorderColor,
                                'width'  : '1.4em',
                                'height' : '1.2em',
                                'background-color': color
                            })
                            .add($('<label>').html(label));

                    $label = $('<span>').addClass('label-list label-' + i).prepend($cell)
                            .data('i', i)
                            .click(toggleSerie)
                            .appendTo($legend);
                    if (s.hide) { this._deactivateSerie( $label ); }
                }

                $legend.find('.label-list').wrap('<div class="col-sm-12 col-md-6 col-lg-4"></div>');
            }
        },

        zoom: function (tsfrom, tsto) {
            if (!tsfrom || !tsto) { return false; }

            $.extend(this.config, {
                from: tsfrom,
                to: tsto
            });

            if (! this.draw() ) { return false; }

            Flotr.bean.fire(
                this.$element.get(0), 'grapher:zoomed', [ tsfrom, tsto ]
            );

            return true;
        },

        export: function() {
            var legend_shown = this.fetched.properties.legend.show;
            if (!legend_shown) {
                this.fetched.properties.legend.show = true;
                this.refresh();
            }
            this.flotr.download.saveImage('png', null, null, false);
            if (!legend_shown) {
                this.fetched.properties.legend.show = legend_shown;
                this.refresh();
            }
        },

        activateSeries: function () {
            var series     = this.fetched.series,
                i;

            for(i = 0; i < series.length; ++i) {
                series[i].hide = false;
            }

            this._activateSerie( this.legend_box.find('> div') );

            this.refresh();
        },

        deactivateSeries: function () {
            var series     = this.fetched.series,
                i;

            for(i = 0; i < series.length; ++i) {
                series[i].hide = true;
            }

            this._deactivateSerie( this.legend_box.find('> div') );

            this.refresh();
        },

        invertActivatedSeries: function () {
            var series  = this.fetched.series,
                $legend = this.legend_box,
                $hidden = $legend.find('label.deactivated').parent(),
                $showed = $legend.find('label:not(.deactivated)').parent(),
                i;

            for(i = 0; i < series.length; ++i) {
                series[i].hide = ! series[i].hide;
            }

            if ($showed.length) { this._deactivateSerie($showed); }
            if ($hidden.length) { this._activateSerie($hidden);   }

            this.refresh();
        },

        observe: function (e, c) {
            return Flotr.EventAdapter.observe( this.$element.get(0), e, c );
        },

        formatDate: function (d, f, m) {
            var tz = '',
                offset;
            if ( m === 'local' ) {
                offset = d.getTimezoneOffset();
                tz += ( offset > 0 ? '-' : '+' );
                offset = Math.abs(offset);
                tz += ('0' + Math.floor(offset/60)).slice(-2) + ('0' + (offset%60)).slice(-2);
            }
            else {
              tz = ' UTC';
            }
            return Flotr.Date.format(d, f, m) + tz;
        }
    };

    // Plugin definition
    $.fn.grapher = function (param) {
        if (typeof param === 'object') {
            return this.each(function () {

                var $this = $(this),
                    grapher = $this.data('grapher'),
                    options;

                if (grapher) { return; }

                options = $.extend({}, {
                        properties: null,
                        id:         null,
                        to:         null,
                        from:       null,
                        url:        null
                    },
                    param
                );

                grapher = new Grapher(this, options);
                $this.data('grapher', grapher);
                $this.data('zooms', []);

                Flotr.EventAdapter.observe($this.find('.plot').get(0), 'flotr:select', function (sel) {
                    $this.data('zooms').push([
                        grapher.config.from,
                        grapher.config.to
                    ]);

                    if ( typeof grapherSelectHook == 'function') {
                      grapherSelectHook(Math.round(sel.x1), Math.round(sel.x2));
                    } else {
                      grapher.zoom(Math.round(sel.x1), Math.round(sel.x2));
                    }
                });

                Flotr.EventAdapter.observe($this.find('.plot').get(0), 'flotr:click', function () {
                    var zo = $this.data('zooms').pop();
                    var x1, x2;
                    if (zo) {
                      x1 = zo[0];
                      x2 = zo[1];
                    } else {
                      x1 = $this.data('grapher').config.from - ($this.data('grapher').config.to - $this.data('grapher').config.from);
                      x2 = $this.data('grapher').config.to + ($this.data('grapher').config.to - $this.data('grapher').config.from);
                    }
                    if ( typeof grapherClickHook == 'function') {
                      grapherClickHook(x1, x2);
                    } else {
                      grapher.zoom(x1, x2);
                    }
                });
            });
        }
        if (! param ) { return $(this).data('grapher'); }
    };

    $.fn.formatUnit = function (val, unit) {
        var scale, steps, i, msecond, second, minute, hour, day, year, res, version;
        switch ( unit ) {
            case 'B':
            case 'Bps':
                if (val <= 1024) { return val + ' ' + unit; }
                scale = [null, 'Ki', 'Mi', 'Gi', 'Ti', 'Pi'];
                for (i=0; i<5 && val > 1024; i++) {
                    val /= 1024;
                }
                return val.toFixed(2) + ' ' + scale[i] + unit;

            case 'KB':
                if (val <= 1024) { return val + ' KiB'; }
                scale = [null, ' MiB', ' GiB', ' TiB', ' PiB'];
                for (i=0; i<4 && val > 1024; i++) {
                    val /= 1024;
                }
                return val.toFixed(2) + scale[i];

            case 'ms':
            case 's':
                msecond = 1;
                second  = (unit === 's')? 1:1000;
                minute  = 60  * second;
                hour    = 60  * minute;
                day     = 24  * hour;
                year    = 365 * day;
                steps   = [ year, day, hour, minute, second, msecond ];
                res     = '';
                scale   = [ 'y ', 'd ', 'h ', 'm ', 's ', 'ms' ];
                for (i=0; i < scale.length; i++) {
                    if (val < steps[i] || val === 0) { continue; }
                    res += Math.floor(val/steps[i]) + scale[i];
                    val = val%steps[i];
                }
                if ( res == ''){
                  return parseFloat(val).toFixed(2) + unit;
                }
                return res;

            case 'PGNUMVER':
                version = parseInt(val / 10000);
                version += '.' + parseInt((val / 100) % 100);
                version += '.' + parseInt((val % 100));
                return version;

            case '':
                if (val <= 1000) { return val; }

                scale = [null, 'K', 'M', 'G', 'T', 'P'];
                for (i=0; i<5 && val > 1000; i++) {
                    val /= 1000;
                }
                return val.toFixed(2) + scale[i];

            default:
                return val + ' '  + unit;
        }
    };

})(jQuery);
