//= require highcharts
//= require highcharts/highcharts-more
//= require highcharts/modules/exporting

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
        var period_group_id = $('dd.active a').data('period-id');
        var metric_name = $('div.tabs-content li.active a.metric-link').data('metric-name');

        drawChartFor(metric_name, period_group_id);

        // register onClick-Handler for all metrics-period-groups
        $('a.metric-link ').click(function(event) {
            event.preventDefault();
            var period_group_id = $('dd.active a').data('period-id');
            var metric_name = $(this).data('metric-name');

            $("ul.side-nav li.active").removeClass('active');
            $(this).parent().addClass('active');

            drawChartFor(metric_name, period_group_id);
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

function drawChartFor(metric_name, period_group_id) {
    $.ajax({
        type: 'GET',
        url: '/reports/metareport/',
        data: { metric: metric_name, period_group: period_group_id },
        async: true,
        dataType: "json",
        success: function (result) {
            drawMetaReportChart(metric_name, period_group_id, result['periods'], result['data']);
        }
    });
}

function drawMetaReportChart(title, period_group_id, periods, data) {
    $('#metareport-chart-' + period_group_id).highcharts({
        title: {
            text: title,
            x: -20 //center
        },
        xAxis: {
            categories: periods
        },
        yAxis: {
            title: {
                text: 'Occurence'
            },
            plotLines: [{
                value: 0,
                width: 1,
                color: '#808080'
            }]
        },
        legend: {
            layout: 'vertical',
            align: 'right',
            verticalAlign: 'middle',
            borderWidth: 0
        },
        series: data
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