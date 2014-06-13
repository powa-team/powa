/**
 * Javascript for page showdbquery.html.ep
 **/

function load(){
  var frompick = $('#fromdatepick').data('DateTimePicker');
  var topick = $('#todatepick').data('DateTimePicker');

  $('[data-graphrole="plot"]').each(function (i, e) {
      $(this).grapher().zoom(
          frompick.getDate().valueOf(),
          topick.getDate().valueOf()
      );
  });
}
