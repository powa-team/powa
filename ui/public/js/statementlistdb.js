/**
 * Javascript for page listdb.html.ep
 **/

// implement load to perform chart data retrieval on period change
function loadChart(){
  var frompick = $('#fromdatepick').data('DateTimePicker');
  var topick = $('#todatepick').data('DateTimePicker');
  var first = ($('#dbdata tbody').find('tr').length == 0);
  $('#dbdata tbody').find('tr').remove();

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
          tmp.append($('<td>').text(val[6]));
          tmp.append($('<td>').text(val[7]));
          tmp.append($('<td>').text(val[8]));
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
