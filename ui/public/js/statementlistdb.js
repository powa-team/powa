/**
 * Javascript for page listdb.html.ep
 **/

// implement select hook to apply zoom in on all data on page
function grapherSelectHook(x1, x2) {
  $('#fromdatepick').data('DateTimePicker').setDate(moment(x1));
  $('#todatepick').data('DateTimePicker').setDate(moment(x2));
  $('#sel_custom').click();
}

// implement sclick hook to apply zoom in on all data on page
function grapherClickHook(x1, x2) {
  $('#fromdatepick').data('DateTimePicker').setDate(moment(x1));
  $('#todatepick').data('DateTimePicker').setDate(moment(x2));
  $('#sel_custom').click();
}

// implement load to perform data retrieval on period change
function load(){
  var frompick = $('#fromdatepick').data('DateTimePicker');
  var topick = $('#todatepick').data('DateTimePicker');
  var first = ($('#dbdata tbody').find('tr').length == 0);
  $('#dbdata tbody').find('tr').remove();


  var frompick = $('#fromdatepick').data('DateTimePicker');
  var topick = $('#todatepick').data('DateTimePicker');

  $('[data-graphrole="plot"]').each(function (i, e) {
      $(this).grapher().zoom(
          frompick.getDate().valueOf(),
          topick.getDate().valueOf()
      );
  });

  $.ajax({
    type: 'POST',
    dataType: 'json',
    url: '/data/statement/listdbdata',
    async: false,
    data: { from: frompick.getDate().valueOf(), to: topick.getDate().valueOf() },
    success: function(d){
      var tmp = '';
      $.each(d.data, function(i,row){ //each query line
        tmp = $('<tr>');
        $.each(row, function(i2,val){ //ech detail for a query, only 1 by query
          tmp.click(function(){ window.location = '/statement/' + val[0]; });
          tmp.append($('<td>').text(val[0]));
          tmp.append($('<td>').text(val[1]));
          tmp.append($('<td>').text(val[2]));
          tmp.append($('<td>').text(val[3]));
          tmp.append($('<td>').text(val[4]));
          tmp.append($('<td>').text(val[5]));
        });
        $('#dbdata tbody').append(tmp);
      });
      if (first){
        $('#dbdata').tablesorter({ sortList: [[0,1]] });
      } else{
         $('#dbdata').trigger("update");
      }
    }
  })
}
