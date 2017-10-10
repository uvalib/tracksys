$(function() {

   var populateRawAvgTimeTable = function(data) {
      var template = "<tr class='data'><td>CAT</td><td>WF</td><td>U</td><td>MIN</td><td>CNT</td><td>AVG</td></tr>";
      var table = $("#avg-time-raw table tbody");
      $.each(data, function(idx, val) {
         $.each(val.workflows, function(idx, wfv) {
            var row = template.replace("CAT", val.category);
            row = row.replace("WF", wfv.name);
            row = row.replace("U", wfv.units);
            row = row.replace("MIN", wfv.mins);
            row = row.replace("CNT", wfv.mf);
            var avg = 0;
            if (wfv.mf > 0 )  avg = Math.round(wfv.mins/wfv.mf);
            row = row.replace("AVG", avg);
            table.append(row);
         });
      });
   };

   var requestAvgTimeReport  = function(start, end) {
      $("#project-time-generating").show();
      $("#avg-time-raw table tbody tr.data").remove();
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

      var params = [];
      if (start) params.push("start="+start);
      if (end) params.push("end="+end);
      if (params.length == 0) {
         alert("At leas an end date is required");
         return;
      }
      url = "/api/reports?type=avg_time&"+params.join("&");
      $.getJSON(url, function ( data, textStatus, jqXHR ){
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
            if ( window.avgTime ) {
               window.avgTime.destroy();
            }
            window.avgTime  = new Chart(ctx, config);
            populateRawAvgTimeTable(data.raw);
         }
      });

   };

   var requestReportsData  = function() {
      requestAvgTimeReport(null, $("#avg-time-end-date").val());
   };

   $("#refresh-avg-time").on("click", function() {
      requestAvgTimeReport($("#avg-time-start-date").val(), $("#avg-time-end-date").val());
   });

   if ( $("#avg-times").length > 0 ) {
      requestReportsData();
   }
});
