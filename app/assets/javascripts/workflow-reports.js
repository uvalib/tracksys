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

   var requestAvgTimeReport  = function(workflowId, start, end) {
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
      params.push("workflow="+workflowId);
      if (start) params.push("start="+start);
      if (end) params.push("end="+end);
      if (params.length == 0) {
         $("#project-time-generating").hide();
         alert("At least an end date is required");
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

   var requestProblemsReport  = function(workflowId, start, end) {
      $("#project-problems-generating").show();
      var config = {
         type: 'bar',
         data: {
            datasets: [{
               backgroundColor: "#cc4444"
            }],
         },
         options: {
            responsive: true,
            title: {
               display: false,
            },
            legend: {
               display: false
            }
         }
      };

      var params = [];
      params.push("workflow="+workflowId);
      if (start) params.push("start="+start);
      if (end) params.push("end="+end);
      if (params.length == 0) {
         $("#project-problems-generating").hide();
         alert("At least an end date is required");
         return;
      }
      url = "/api/reports?type=problems&"+params.join("&");
      $.getJSON(url, function ( data, textStatus, jqXHR ){
         $("#project-problems-generating").hide();
         if (textStatus == "success" ) {
            config.data.datasets[0].data = data.data;
            config.data.labels = data.labels;
            var ctx = document.getElementById("problems-chart").getContext("2d");
            if ( window.problemsChart ) {
               window.problemsChart.destroy();
            }
            window.problemsChart = new Chart(ctx, config);
         }
      });
   };

   var chartColors = [
      "#e6194b", "#11aaff", "#ffe119", "#000080", "#f58231",
      "#911eb4", "#808080", "#008080", "#e6beff", "#aaffc3"];

   var requestCategoriesReport = function() {
      $("#project-categories-generating").show();
      var config = {
         type: 'pie',
         data: {
            datasets: [{
               backgroundColor: chartColors
            }],
         },
         options: {
            responsive: true,
            title: {
               display: false,
            },
            legend: {
               display: true
            }
         }
      };
      $.getJSON("/api/reports?type=categories", function ( data, textStatus, jqXHR ){
         $("#project-categories-generating").hide();
         if (textStatus == "success" ) {
            config.data.datasets[0].data = data.data;
            config.data.labels = data.labels;
            var canvas = document.getElementById("categories-chart");
            var ctx = canvas.getContext("2d");
            var pie = new Chart(ctx, config);
            $("#total-projects").text("Total projects: "+data.total);
         }
      });
   };

   var requestRejectionsReport = function(workflowId, start, end) {
      $("#project-rejections-generating").show();
      var config = {
         type: 'pie',
         data: {
            datasets: [{
               backgroundColor: chartColors
            }],
         },
         options: {
            responsive: true,
            title: {
               display: false,
            },
            legend: {
               display: true
            }
         }
      };
      var params = [];
      params.push("workflow="+workflowId);
      if (start) params.push("start="+start);
      if (end) params.push("end="+end);
      if (params.length < 2) {
         $("#project-problems-generating").hide();
         alert("A workflow and end date are required");
         return;
      }
      $.getJSON("/api/reports?type=rejections&"+params.join("&"), function ( data, textStatus, jqXHR ){
         $("#project-rejections-generating").hide();
         if (textStatus == "success" ) {
            config.data.datasets[0].data = data.data;
            config.data.labels = data.labels;
            var canvas = document.getElementById("rejections-chart");
            var ctx = canvas.getContext("2d");
            if ( window.rejectionsChart ) {
               window.rejectionsChart.destroy();
            }
            window.rejectionsChart = new Chart(ctx, config);
            var txt = "<b>Total Assignments:</b> "+data.total_assigments;
            txt += ", <b>Total Rejections:</b> "+data.total_rejects+", <b>Rejection Percentage:</b> "+data.reject_percent+"%";
            $("#total-assignments").html(txt);
         }
      });
   };

   var requestReportsData  = function() {
      requestAvgTimeReport(1, null, $(".avg-time.report-end").val());
      requestCategoriesReport();
      requestProblemsReport(1, null, $(".problems.report-end").val());
      requestRejectionsReport(1, null, $(".rejections.report-end").val());
   };

   $(".refresh-report").on("click", function() {
      var id = $(this).attr("id");
      var start = $(".report-start."+id).val();
      var end = $(".report-end."+id).val();
      var wfId = $(".workflow."+id).val();
      if (id == "problems") {
         requestProblemsReport(wfId, start, end);
      } else if (id == "rejections") {
         requestRejectionsReport(wfId, start, end);
      } else {
         requestAvgTimeReport(wfId, start, end);
      }
   });

   if ( $("#avg-times").length > 0 ) {
      requestReportsData();
   }
});
