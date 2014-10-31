/**
 * Javascript for powa pages
 **/

// Return GET from and to params
function getInterval() {
  var from = $('body').data('from');
  var to = $('body').data('to');
  if ( from != "" && to != "" ) {
    return "?from=" + from + "&to=" + to;
  }
  return "";
}

// href for a db page
function getDbUrl(datname) {
  return '/statement/' + datname + getInterval();
}

// href for a query page
function getQueryUrl(datname, md5query) {
  return '/statement/' + datname + '/' + md5query + getInterval();
}

// Format time values, call formatUnit in grapher.js. Used in tables.
function timeFormatter(val,row,index) {
  return $.fn.formatUnit(val,'ms');
}

// Format byte values, call formatUnit in grapher.js. Used in tables.
function byteFormatter(val,row,index) {
  return $.fn.formatUnit(val,'B');
}

// Format queries. Used in table in showdb page.
function queryFormatter(val,row,index) {
  return '<button class="btn btn-info btn-xs btn-query" title="View query text"><span class="glyphicon glyphicon-fullscreen"></span></button> '
    + '<a href="' + getQueryUrl($('#dbname').text(), row.md5query) + '"><button class="btn btn-default btn-xs" title="View query charts"><span class="glyphicon glyphicon-search" title="View query charts"></span></button></a> '
    + row.short_query;
}

// Format database (only add a button). Used in table in listdb page.
function dbFormatter(val,row,index) {
  return '<a href="' + getDbUrl(row.datname) + '"><button class="btn btn-default btn-xs" title="View database charts"><span class="glyphicon glyphicon-search" title="View query charts"></span></button></a> '
    + row.datname;
}

// Sort values using numeric values. Used when sorting tables.
function customSorter(a,b){
  a = Number(a);
  b = Number(b);
  if (a > b) return 1;
  if (a < b) return -1;
  return 0;
}

// Display prettified query on click in showdb table.
window.queryModal = {
  'click .btn-query': function (e,value,row,index) {
    $('#query-content').html(row.query);
    $('#query').modal();
  }
}

// implement select hook to apply zoom in on all data on page
function grapherSelectHook(x1, x2) {
  applyZoom(x1,x2);
}

// implement sclick hook to apply zoom in on all data on page
function grapherClickHook(x1, x2) {
  applyZoom(x1,x2);
}

function applyZoom(x1, x2) {
  var from = moment(x1).format('YYYY-MM-DD HH:mm:ss');
  var to = moment(x2).format('YYYY-MM-DD HH:mm:ss');
  $('body').data('from', from);
  $('body').data('to', to);
  $('#fromdatepick').data('DateTimePicker').setDate(moment(x1));
  $('#todatepick').data('DateTimePicker').setDate(moment(x2));
  $('#sel_custom').click();
  window.history.replaceState( {}, '', current_route
    + '?from=' + from
    + '&to=' + to
  );
  $('.change-page').each(function() {
    var href = $(this).attr('href');
    href = href.replace(/\?from=.*/,'');
    href = href + getInterval();
    $(this).attr('href',href);
  });
}

$(document).ready(function () {
  /* bind the datetimepicker to the date fields */
  $('.datepick').datetimepicker({
    format: 'YYYY-MM-DD HH:mm:ss'
  });

  $('[data-graphid]').each(function () {
    var $this = $(this),
        $plot_box = $this.find('[data-graphrole="plot"]'),
        $legend_box = $this.find('[data-graphrole="legend"]'),
        $grapher;
    $plot_box.grapher({
      url: $this.attr('data-graphurl'),
      id: $this.attr('data-graphid'),
      legend_box: $legend_box
    });
    $grapher = $plot_box.data('grapher');

    // Setup actions on buttons toolbar
    $this.find('[data-graphrole="offon-series"]').data('selectall', 'true').click(function (e) {
      e.preventDefault();
      var selectall = !$(this).data('selectall');
      if (selectall)
          $grapher.activateSeries();
      else
          $grapher.deactivateSeries();
      $(this).data('selectall', selectall);
    });

    $this.find('[data-graphrole="invert-series"]').click(function(e){
      e.preventDefault();
      $grapher.invertActivatedSeries();
    });
    // Export the graph
    $this.find('[data-graphrole="export-graph"]').click(function(e){
        e.preventDefault();
        $grapher.export();
    });



    $grapher.observe('grapher:zoomed', function (from, to) {
        var $this = $(this),
          grapher  = $this.grapher();

        // FIXME: do not use flotr props to get min/max date
        $(this).parent().siblings().find('> span').get(0)
          .innerHTML = ''+ grapher.formatDate(new Date(grapher.flotr.axes.x.datamin), grapher.fetched.properties.xaxis.timeFormat, grapher.fetched.properties.xaxis.timeMode)
            +'&nbsp;&nbsp;-&nbsp;&nbsp;'+ grapher.formatDate(new Date(grapher.flotr.axes.x.datamax),  grapher.fetched.properties.xaxis.timeFormat, grapher.fetched.properties.xaxis.timeMode);
    });
  });

  $('.scales .btn').click(function (e) {
    var toDate;
    var base_timestamp = $(this).parents('.scales').data('base-timestamp');
    if ( base_timestamp !== undefined ) {
      toDate = moment(base_timestamp);
    } else {
      toDate = moment();
    }
    var fromDate = moment(toDate);
    var frompick = $('#fromdatepick').data('DateTimePicker');
    var topick = $('#todatepick').data('DateTimePicker');
    var error = false;

    switch($(this).attr('id')) {
      case 'sel_month':
        fromDate.subtract('month',1);
      break;
      case 'sel_week':
        fromDate.subtract('day',7);
      break;
      case 'sel_day':
        fromDate.subtract('day',1);
      break;
      case 'sel_hour':
        fromDate.subtract('hour',1);
      break;
      case 'sel_custom':
        if (frompick.getDate() === null ) {
          alert('you must set the starting date.');
          return false;
        }
        if (topick.getDate() === null)
          /* set the toDate to the current day */
          topick.setDate(toDate.toDate());
        else
          toDate = topick.getDate();

        fromDate = frompick.getDate();
      break;
      default:
        error = true;
    }
    if ( !error) {
      frompick.setDate(fromDate.toDate());
      topick.setDate(toDate.toDate());

      $('[data-graphrole="plot"]').each(function (i, e) {
          $(this).grapher().zoom(
              fromDate.valueOf(),
              toDate.valueOf()
          );
      });

      loadChart(); //overloaded in specific template
    }
  });

  $('.go-forward').click(function (e) {
    var frompick = $('#fromdatepick').data('DateTimePicker'),
      topick   = $('#todatepick').data('DateTimePicker'),
      fromDate = frompick.getDate().valueOf(),
      toDate   = topick.getDate().valueOf(),
      delta    = toDate - fromDate;

    e.preventDefault();
    fromDate += delta;
    toDate   += delta;

    frompick.setDate(new Date(fromDate));
    topick.setDate(new Date(toDate));
    $('#sel_custom').click();

  });

  $('.go-backward').click(function (e) {
    var frompick = $('#fromdatepick').data('DateTimePicker'),
      topick   = $('#todatepick').data('DateTimePicker'),
      fromDate = frompick.getDate().valueOf(),
      toDate   = topick.getDate().valueOf(),
      delta    = toDate - fromDate;

    e.preventDefault();

    fromDate -= delta;
    toDate   -= delta;

    frompick.setDate(new Date(fromDate));
    topick.setDate(new Date(toDate));
    $('#sel_custom').click();
  });

  $('.sql').dblclick(function () {
    if (this.style == undefined || this.style.whiteSpace == 'pre') {
      this.style.whiteSpace ='normal';
    } else {
      this.style.whiteSpace = 'pre';
    }
  });

  /* By default, display data from the last hour,
     unless from and to GET params are valued
  */
  var from = $('body').data('from');
  var to = $('body').data('to');
  if ( from != '' && to != '' ) {
    applyZoom(moment(from).valueOf(), moment(to).valueOf())
  } else {
    if ($('#todatepick').length != 0){
      $('#sel_hour').click();
    }
  }
});
