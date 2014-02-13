# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  oTable = $('#files-table').dataTable
    bProcessing: true
    bServerSide: true
    sAjaxSource: $('#files-table').data('source')
    aaSorting: [[2, 'desc']],
    aoColumns: [
        { "sWidth": "40%" },
        { "sWidth": "20%" },
        { "sWidth": "20%" },
        { "sWidth": "10%" },
        { "sWidth": "5%" },
        { "sWidth": "5%" },
    ],