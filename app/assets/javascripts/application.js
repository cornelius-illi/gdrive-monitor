// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require foundation
//= require jquery.dataTables.min
//= require dataTables.foundation
//= require turbolinks
//= require_tree .

$(function(){
    $(document).foundation({
        alert: {
            animation_speed: 500,
            animation: 'fadeOut'
        }
    });


    $(document).ready(function() {
        $('#files-table').dataTable();
    } );

    $( "a.active-report-col" ).click(function() {
        column = parseInt( $(this).attr('href').split('-')[1]) + 1;
        $(".reference").removeClass("reference");
        $("span.difference").remove();

        $("tr th:nth-child(" + column + ")").addClass("reference");
        $("tr td:nth-child(" + column + ")").addClass("reference");

        $(".tabs-content .active td").each(function() {
            // @todo: first not working ...? ... and why is nothing add to the reference column?
            if( !$(this).is(':first') ) {
                reference_value = parseFloat($(this).siblings("td:nth-child(" + column + ")").text());
                my_value = parseFloat($(this).text());
                if (!isNaN(reference_value) && !isNaN(my_value)) {
                    diff = Math.round( ( (my_value-reference_value)/my_value) * 100 * 100) / 100
                    diff = (my_value == 0) ? 0 : diff

                    sign_class = (diff > 0) ? "positive" : "negative";
                    arrow_class = (diff > 0) ? "up" : "down";

                    if(diff == 0) {
                        sign_class = ""
                        arrow_class = "right"
                    }

                    $(this).append('<span class="difference">, <span class="' + sign_class + '"><span class="fi-arrow-' + arrow_class + '"></span> ' + diff + '%</span></span></span>');
                }
            }
        });
    });
});
