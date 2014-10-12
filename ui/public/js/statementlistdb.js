/**
 * Javascript for page listdb.html.ep
 **/

// implement load to perform chart data retrieval on period change
function loadChart(){
  var frompick = $('#fromdatepick').data('DateTimePicker');
  var topick = $('#todatepick').data('DateTimePicker');
  $('#dbdata').bootstrapTable('destroy');

  $('#dbdata').bootstrapTable({
    method: 'get',
    url: '/data/statement/listdbdata',
    queryParams: function(params){
      return {
        'from': frompick.getDate().valueOf(),
        'to': topick.getDate().valueOf()
      };
    },
    cache: false,
    queryParamsType: 'limit',
    responseHandler: function(res){ return res.data; },
    search: true,
    pagination: true,
    pageSize: 10,
    pageList: [10, 25, 50, 100, 200],
    showColumns: true,
    sortName: 'total_calls',
    sortOrder: 'desc',
    columns: [{
        field: 'datname',
        title: 'Database',
        sortable: true,
        formatter: dbFormatter,
      }, {
        field: 'total_calls',
        title: '# Calls',
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
        title: 'Avg. runtime',
        sortable: true,
        formatter: timeFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_read',
        title: 'Blocks read',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_hit',
        title: 'Blocks hit',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_dirtied',
        title: 'Blocks dirtied',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_blks_written',
        title: 'Blocks written',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'total_temp_blks_written',
        title: 'Temp blocks written',
        sortable: true,
        formatter: byteFormatter,
        sorter: customSorter
      }, {
        field: 'io_time',
        title: 'I/O time',
        sortable: true,
        formatter: timeFormatter,
        sorter: customSorter
    }],
    onDblClickRow: function(row){
      window.location = getDbUrl(row.datname);
    }
  });
}
