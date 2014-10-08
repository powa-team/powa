/**
 * Javascript for page showdbquery.html.ep
 **/

function loadChart(){
  var frompick = $('#fromdatepick').data('DateTimePicker');
  var topick = $('#todatepick').data('DateTimePicker');
  var first = ($('#dbdata tbody').find('tr').length == 0);
  $('#dbdata').bootstrapTable('destroy');

  $('#dbdata').bootstrapTable({
    method: 'get',
    url: '/data/statement/querydata',
    queryParams: function(params){
      return {
        'md5query': md5query,
        'from': frompick.getDate().valueOf(),
        'to': topick.getDate().valueOf()
      };
    },
    cache: false,
    queryParamsType: 'limit',
    responseHandler: function(res){ return res.data; },
    columns: [{
        field: 'total_calls',
        title: '#Calls',
        sorter: customSorter
      }, {
        field: 'total_runtime',
        title: 'Runtime',
        formatter: timeFormatter,
        sorter: customSorter
      }, {
        field: 'avg_runtime',
        title: 'Avg. runtime',
        formatter: timeFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_read',
        title: 'Blocks read',
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_hit',
        title: 'Blocks hit',
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_dirtied',
        title: 'Blocks dirtied',
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_written',
        title: 'Blocks written',
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_temp_blks_read',
        title: 'Temp blocks read',
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_temp_blks_written',
        title: 'Temp blocks written',
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blk_read_time',
        title: 'Block read time',
        formatter: timeFormatter,
        sorter: customSorter
      }, {
        field: 'total_blk_write_time',
        title: 'Block write time',
        formatter: timeFormatter,
        sorter: customSorter
    }]
  });
}
