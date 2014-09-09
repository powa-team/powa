/**
 * Javascript for page showdb.html.ep
 **/

// implement load to perform chart data retrieval on period change
function loadChart(){
  var frompick = $('#fromdatepick').data('DateTimePicker');
  var topick = $('#todatepick').data('DateTimePicker');
  var first = ($('#dbdata tbody').find('tr').length == 0);
  $('#dbdata tbody').find('tr').remove();
  $('#query-list').empty();

  $.ajax({
    type: 'POST',
    dataType: 'json',
    url: '/data/statement/dbdata',
    async: false,
    data: { dbname: $('#dbname').text(), from: frompick.getDate().valueOf(), to: topick.getDate().valueOf() },
    success: function(d){
      var chart = '';
      var query = '';
      $.each(d.data, function(i,row){ //each query line

        $.each(row, function(i2,val){ //ech detail for a query, only 1 by query
          chart = $('<tr>');
          chart.attr('id','row-' + val[9]);
          query = $('<div>').attr('id',val[9]).addClass('box hid sql sql-middlesize').html(val[10]);
          chart.click(function(){ window.location = '/statement/' + $('#dbname').text() + '/' + val[9]; });
          chart.append($('<td>').text(val[0]));
          chart.append($('<td>').text(val[1]));
          chart.append($('<td>').text(val[2]));
          chart.append($('<td>').text(val[3]));
          chart.append($('<td>').text(val[4]));
          chart.append($('<td>').text(val[5]));
          chart.append($('<td>').text(val[6]));
          chart.append($('<td>').text(val[7]));
          chart.append($('<td>').text(val[8]).mouseenter(function(e){
            var p = $('#row-'+val[9]).position();
            var h1 = $('#row-'+val[9]).height();
            var h2 = $('#'+val[9]).height();
            $('#' + val[9]).css({top: p.top-h1-h2, left: p.left}).fadeIn();
          }).mouseleave(function(e){
            $('#' + val[9]).fadeOut();
          }));
        });
        $('#dbdata tbody').append(chart);
        $('#query-list').append(query);
      });
      if (first){
        $('#dbdata').tablesorter({ sortList: [[0,1]] });
      } else{
         $('#dbdata').trigger("update");
      }
    }
  })
}
