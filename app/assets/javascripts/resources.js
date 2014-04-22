//= require highcharts

$(document).ready(function() {
    // if on page /reports/metareport/
    if ($('.scatter_chart_div').length) {

        $('.scatter_chart_div').each(function() {
            var id = '#' + $(this).attr('id');
            var idAr = id.split('_');
            var index = idAr[idAr.length -1];
            $.ajax({
                type: 'GET',
                url: '/show_threshold/',
                data: { resultid: index },
                async: true,
                dataType: "json",
                success: function (result) {
                    drawScatterChart(id, result);
                }
            });
        });
    }
});

function drawScatterChart(id, result) {
    $(id).highcharts({
        chart: { type: 'scatter', zoomType: 'xy' },
        title: { text: result['title'] },
        xAxis: {
            title: { enabled: true, text: result['x_title'] },
            startOnTick: true,
            endOnTick: true,
            showLastLabel: true
        },
        yAxis: {
            title: { text: result['y_title'] }
        },
        plotOptions: {
            scatter: {
                marker: {
                    radius: 5,
                    states: {
                        hover: {
                            enabled: true,
                            lineColor: 'rgb(100,100,100)'
                        }
                    }
                },
                states: {
                    hover: {
                        marker: {
                            enabled: false
                        }
                    }
                },
                tooltip: {
                    headerFormat: '<b>{series.name}</b><br>',
                    pointFormat: '{point.x}, {point.y}'
                }
            }
        },
        series: result['data']
    });
}
