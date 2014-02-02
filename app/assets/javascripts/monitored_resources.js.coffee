# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $('#files-table').dataTable
    sAjaxSource: $('#files-table').data('source')
    bDeferRender: true
    bProcessing: true
    aoColumns: [{"mDataProp":"shortened_title"},
      { "mDataProp":"details"},
      { "mDataProp":"created_date"},
      { "mDataProp":"modified_date"},
      { "mDataProp":"revision_count"},
      { "mDataProp":"collaborators_count"},
      { "mDataProp":"globally"}]
    aaSorting: [[3, 'desc']]