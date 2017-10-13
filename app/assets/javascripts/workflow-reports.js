$(function() {

   var populateRawAvgTimeTable = function(data) {
      var template = "<tr class='data'><td>CAT</td><td>U</td><td>MIN</td><td>CNT</td><td>AVG</td></tr>";
      var table = $("#avg-time-raw table tbody");
      for (var key in data) {
         var rowData = data[key];
         var row = template.replace("CAT", key);
         row = row.replace("WF", rowData.name);
         row = row.replace("U", rowData.units);
         row = row.replace("MIN", rowData.mins);
         row = row.replace("CNT", rowData.mf);
         var avg = 0;
         if (rowData.mf > 0 )  avg = Math.round(rowData.mins/rowData.mf);
         row = row.replace("AVG", avg);
         table.append(row);
      }
   };

   var populateRawRejectionsTable = function(data) {
      var template = "<tr class='data'><td>STEP</td><td>CNT</td><td>MIN</td><td>AVG</td></tr>";
      var table = $("#rejections-raw tbody");
      $("#rejections-raw table tbody tr.data").remove();
      var rowData, row;
      for (var key in data.raw) {
         rowData = data.raw[key];
         row = template.replace("STEP", key);
         row = row.replace("CNT", rowData.rejections);
         row = row.replace("MIN", rowData.time);
         var avg = 0;
         if (rowData.rejections > 0 )  avg = Math.round(rowData.time/rowData.rejections);
         row = row.replace("AVG", avg);
         table.append(row);
      }

      $("#top-rejectors .panel_contents, #most-rejected .panel_contents").empty();
      var t2= "<div><span class='reject-name'>NAME:</span><span>CNT</span></div>";
      for (key in data.top_rejectors) {
         row = t2.replace("NAME", key);
         row = row.replace("CNT", data.top_rejectors[key]);
         $("#top-rejectors .panel_contents").append(row);
      }
      for (key in data.most_rejected) {
         row = t2.replace("NAME", key);
         row = row.replace("CNT", data.most_rejected[key]);
         $("#most-rejected .panel_contents").append(row);
      }
   };

   var requestAvgTimeReport  = function(workflowId, start, end) {
      if (start.length == 0 || end.length == 0) {
         alert("Start and End dates are required");
         return;
      }
      $("#project-time-generating").show();
      $("#avg-time-raw table tbody tr.data").remove();
      var config = {
         type: 'bar',
         data: {
            datasets: [{
               backgroundColor: "#44aacc"
            }]
         },
         options: {
            responsive: true,
            title: {
               display: false,
            },
            legend: {
               display: false
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
                     return data.datasets[0].label;
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
      params.push("start="+start);
      params.push("end="+end);
      url = "/api/reports?type=avg_time&"+params.join("&");
      $.getJSON(url, function ( data, textStatus, jqXHR ){
         $("#project-time-generating").hide();
         if (textStatus == "success" ) {
            config.data.datasets[0].data = data.data;
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
      if (start.length == 0 || end.length == 0) {
         alert("Start and End dates are required");
         return;
      }
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
      params.push("start="+start);
      params.push("end="+end);
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

   var requestCategoriesReport = function(workflowId, start, end) {
      if (start.length == 0 || end.length == 0) {
         alert("Start and End dates are required");
         return;
      }
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
      var params = [];
      params.push("workflow="+workflowId);
      params.push("start="+start);
      params.push("end="+end);
      $.getJSON("/api/reports?type=categories&"+params.join("&"), function ( data, textStatus, jqXHR ){
         $("#project-categories-generating").hide();
         if (textStatus == "success" ) {
            config.data.datasets[0].data = data.data;
            config.data.labels = data.labels;
            var canvas = document.getElementById("categories-chart");
            var ctx = canvas.getContext("2d");
            if ( window.categoriesChart ) {
               window.categoriesChart.destroy();
            }
            window.categoriesChart = new Chart(ctx, config);
            $("#total-projects").text("Total projects: "+data.total);
         }
      });
   };

   var requestRejectionsReport = function(workflowId, start, end) {
      if (start.length == 0 || end.length == 0) {
         alert("Start and End dates are required");
         return;
      }
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
      params.push("start="+start);
      params.push("end="+end);
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
            populateRawRejectionsTable(data);
         }
      });
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
      } else if (id == "categories") {
         requestCategoriesReport(wfId, start, end);
      } else {
         requestAvgTimeReport(wfId, start, end);
      }
   });

   if ( $("#avg-times").length > 0 ) {
      requestAvgTimeReport(1, $(".avg-time.report-start").val(), $(".avg-time.report-end").val());
      requestCategoriesReport(1, $(".categories.report-start").val(), $(".categories.report-end").val());
      requestProblemsReport(1, $(".problems.report-start").val(), $(".problems.report-end").val());
      requestRejectionsReport(1, $(".rejections.report-start").val(), $(".rejections.report-end").val());
   }
});
