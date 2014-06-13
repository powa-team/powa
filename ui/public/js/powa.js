/**
 * Javascript for powa pages
 **/
$(document).ready(function () {
  /* bind the datetimepicker to the date fields */
  $('.datepick').datetimepicker({
    format: 'DD/MM/YYYY HH:mm:ss'
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
    var fromDate = new Date();
    var toDate = new Date();
    var frompick = $('#fromdatepick').data('DateTimePicker');
    var topick = $('#todatepick').data('DateTimePicker');
    var error = false;

    switch($(this).attr('id')) {
      case 'sel_year':
          fromDate.setYear(fromDate.getYear() + 1900 - 1);
        break;
        case 'sel_month':
          fromDate.setMonth(fromDate.getMonth() - 1);
        break;
        case 'sel_week':
          fromDate.setDate(fromDate.getDate() - 7);
        break;
        case 'sel_day':
          fromDate.setDate(fromDate.getDate() - 1);
        break;
        case 'sel_custom':
          if (frompick.getDate() === null ) {
            alert('you must set the starting date.');
            return false;
          }
          if (topick.getDate() === null)
            /* set the toDate to the current day */
            topick.setDate(toDate.getDate());
          else
            toDate = topick.getDate();

          fromDate = frompick.getDate();
        break;
        default:
          error = true;
    }
    if ( !error) {
      frompick.setDate(fromDate);
      topick.setDate(toDate);

      load(); //overloaded in specific template
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

  /* by default, display data from the last hour */
  if ($('#todatepick').length != 0){
    var _date = new Date();
    $('#todatepick').data('DateTimePicker').setDate(_date);
    _date.setHours(_date.getHours()-1);
    $('#fromdatepick').data('DateTimePicker').setDate(_date);
    $('#sel_custom').click();
  }
});
