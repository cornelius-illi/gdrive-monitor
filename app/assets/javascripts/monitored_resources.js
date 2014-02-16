(function() {
    jQuery(function() {
        var oTable;
        oTable = $('#files-table').dataTable({
            bProcessing: true,
            bServerSide: true,
            sAjaxSource: $('#files-table').data('source'),
            fnServerParams: function ( aoData ) {
                aoData.push(
                    {"name": "filter_periods", "value": $('#filter_periods').val() },
                    {"name": "filter_mimetype", "value": $('#filter_mimetype').val()} )
                ;
            },
            aaSorting: [[2, 'desc']],
            aoColumns: [
                {
                    "sWidth": "40%"
                }, {
                    "sWidth": "20%"
                }, {
                    "sWidth": "20%"
                }, {
                    "sWidth": "10%"
                }, {
                    "sWidth": "5%"
                }, {
                    "sWidth": "5%"
                }
            ]
        });
    });

}).call(this);

$(document).ready(function() {
    $('#filter_periods').change( function() { $('#files-table').dataTable().fnDraw(); });
    $('#filter_mimetype').change( function() { $('#files-table').dataTable().fnDraw(); });
});