/**
 * Javascript for page showdb.html.ep
 **/

// implement load to perform chart data retrieval on period change
function loadChart(){
  var frompick = $('#fromdatepick').data('DateTimePicker');
  var topick = $('#todatepick').data('DateTimePicker');
  var first = ($('#dbdata tbody').find('tr').length == 0);
  $('#dbdata').bootstrapTable('destroy');

  $('#dbdata').bootstrapTable({
    method: 'get',
    url: '/data/statement/dbdata',
    queryParams: function(params){
      return {
        'dbname': $('#dbname').text(),
        'from': frompick.getDate().valueOf(),
        'to': topick.getDate().valueOf()
      };
    },
    cache: false,
    queryParamsType: 'limit',
    responseHandler: function(res){ return res.data; },
    search: true,
    pagination: true,
    pageSize: 15,
    pageList: [15, 25, 50, 100, 200],
    showColumns: true,
    sortName: 'total_calls',
    sortOrder: 'desc',
    columns: [{
        field: 'total_calls',
        title: '#Calls',
        sortable: true,
        sorter: customSorter
      }, {
        field: 'total_runtime',
        title: 'Runtime',
        sortable: true,
        formatter: timeFormatter,
        sorter: customSorter
      }, {
        field: 'avg_runtime',
        title: 'Avg.<br />runtime',
        sortable: true,
        formatter: timeFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_read',
        title: 'Blocks<br />read',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_hit',
        title: 'Blocks<br />hit',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_dirtied',
        title: 'Blocks<br />dirtied',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_written',
        title: 'Blocks<br />written',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_temp_blks_read',
        title: 'Temp<br />blocks read',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_temp_blks_written',
        title: 'Temp<br />blocks written',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blk_read_time',
        title: 'Block<br />read time',
        sortable: true,
        formatter: timeFormatter,
        sorter: customSorter
      }, {
        field: 'total_blk_write_time',
        title: 'Block<br />write time',
        sortable: true,
        formatter: timeFormatter,
        sorter: customSorter
      }, {
        field: 'query',
        title: 'Query',
        sortable: true,
        formatter: queryFormatter,
        events: queryModal,
        class: 'truncate'
    }],
    onDblClickRow: function(row){
      window.location = getQueryUrl($('#dbname').text(), row.md5query);
    }
  });

  $('#toolbar').find('select').change(function () {
    $('table').bootstrapTable('refreshOptions', {
      exportDataType: 'all'
    });
  });
}
