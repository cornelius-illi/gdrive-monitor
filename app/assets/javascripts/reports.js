//= require highcharts
//= require highcharts/highcharts-more
//= require highcharts/modules/exporting
//= require regression.js

// reports.index
function calculate_diffs() {
    $(".tabs-content .active td").each(function() {
        // @todo: first not working ...? ... and why is nothing add to the reference column?
        if( !$(this).is(':first') ) {
            reference_value = parseFloat($(this).siblings("td.isnumber:nth-child(" + column + ")").text());
            my_value = parseFloat($(this).text());
            if (!isNaN(reference_value) && !isNaN(my_value)) {
                diff = Math.round( ( (my_value-reference_value)/reference_value) * 100 * 100) / 100
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
}

$( "a.active-report-col" ).click(function() {
    column = parseInt( $(this).attr('href').split('-')[1]) + 1;
    $(".reference").removeClass("reference");
    $("span.difference").remove();

    $("tr th:nth-child(" + column + ")").addClass("reference");
    $("tr td:nth-child(" + column + ")").addClass("reference");

    calculate_diffs();
});

// reports.metareport
$(document).ready(function() {
    // if on page /reports/metareport/
    if ($('.metareport-charts').length) {
        // find active metric + period-group and draw chart
        var metric_name = $('li.active a.metric-link').data('metric-name');

        drawChartFor(metric_name);

        // register onClick-Handler for all metrics-period-groups
        $('a.metric-link ').click(function(event) {
            event.preventDefault();
            var metric_name = $(this).data('metric-name');

            $("ul.side-nav li.active").removeClass('active');
            $(this).parent().addClass('active');

            drawChartFor(metric_name);
        });
    }

    // reports.statistics
    var id = '#mimetype-boxplot';
    if ($(id).length) {
        $.ajax({
            type: 'GET',
            url: '/reports/statistics',
            async: true,
            dataType: "json",
            success: function (result) {
                var title = 'Top 15 Mime-Types and their number of revisions (Tukey boxplot)'
                drawBoxPlot(id, title, result['categories'], result['data']);
            }
        });
    }
});

function drawChartFor(metric_name) {
    $.ajax({
        type: 'GET',
        url: '/reports/metareport/',
        data: { metric: metric_name },
        async: true,
        dataType: "json",
        success: function (result) {
            drawMetaReportChart(metric_name, result['periods'], result['data']);
        }
    });
}

function drawMetaReportChart(title, periods, data) {
    var chart_type = "line"; // "scatter"
    $('#metareport-chart').highcharts({
        title: {
            text: title,
            x: -20 //center
        },
        //colors: ['#C7C7C7','#BEEFBE','#7EDF7E', '#A6B8ED','#4D70DB','#F3C2C2','#E06666'],
        colors: ['#BEEFBE', '#A6B8ED','#F3C2C2'],
        // colors: ['#0000FF', '#3399FF', '#006600', '#00CC00', '#CC0000', '#FF6666'],
        xAxis: {
            categories: periods,
            labels: {
                rotation: -45,
                style: {
                    fontSize:'15px'
                }
            }
        },
        yAxis: {
            type: 'linear',
            min: 0.0,
            ceiling: 8,
            title: {
                text: 'Occurence'
            },
            plotLines: [{
                value: 1,
                width: 3,
                color: '#808080'
            }]
        },
        legend: {
            layout: 'vertical',
            align: 'right',
            verticalAlign: 'middle',
            borderWidth: 0
        },
        exporting: {
            sourceWidth: 1600,
            sourceHeight: 800
        },
        series: [{
            type: chart_type,
            name: data[1]['name'],
            data: data[1]['data']
        },{
            type: chart_type,
            name: data[2]['name'],
            data: data[2]['data']
        },{
            type: chart_type,
            name: data[3]['name'],
            data: data[3]['data']
        }]
    });
}

// reports.statistics
function drawBoxPlot(id, title, categories, data) {
    $(id).highcharts({
        chart: { type: 'boxplot' },
        title: { text: title },
        legend: { enabled: false },

        xAxis: {
            categories: categories,
            title: { text: 'Mime-Type ordered by rank (most used starts left)' }
        },

        yAxis: {
            title: {
                text: 'Number of Revisions'
            }
        },

        series: [{
            name: 'Number of revisions/ mime_type',
            data: data
        }]
    });
}