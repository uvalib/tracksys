$(function() {

   var requestAvgTimeReport  = function() {
      $("#project-time-generating").show();
      var config = {
         type: 'bar',
         data: {
            datasets: [{
               data: [],
               borderWidth: 1,
               backgroundColor: "#44aacc"
            }],
            labels: []
         },
         options: {
            responsive: true,
            title: {
               display: false,
            },
            scales: {
               yAxes: [{
                  ticks: {
                     callback: function(value, index, values) {
                        return value + ' mins';
                     }
                  }
               }]
            },
            tooltips: {
               callbacks: {
                  title: function(tooltipItem, data) {
                     return data.datasets[tooltipItem[0].datasetIndex].label;
                  },
                  label: function(tooltipItem, data) {
                     return Number(tooltipItem.yLabel) + " mins / page";
                  }
               }
            }
         }
      };

      $.getJSON("/api/reports?type=avg_time", function ( data, textStatus, jqXHR ){
         $("#project-time-generating").hide();
         if (textStatus == "success" ) {
            var colors = ["#44aacc", "#cc4444", "#44cc44", "#ccaacc", "#ccaa44"];
            $.each(data.datasets, function(idx, val) {
               val.backgroundColor = colors[idx];
               val.borderWidth = 0;
            });
            config.data.datasets = data.datasets;
            config.data.labels = data.labels;
            var ctx = document.getElementById("avg-times").getContext("2d");
            window.avgTime  = new Chart(ctx, config);
         }
      });

   };

   var requestReportsData  = function() {
      requestAvgTimeReport();
   };


   if ( $("#avg-times").length > 0 ) {
      requestReportsData();
   }
});
