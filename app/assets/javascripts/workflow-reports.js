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

   var getBasicChartCfg = function(type) {
      var chartColors = [
         "#e6194b", "#11aaff", "#ffe119", "#000080", "#f58231",
         "#911eb4", "#808080", "#008080", "#e6beff", "#aaffc3"];

      config = {
         type: type,
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
            }
         }
      };
      if (type === "bar") {
         config.data.datasets[0].backgroundColor = "#44aacc";
      } else  {
         config.data.datasets[0].backgroundColor = chartColors;
      }
      return config;
   };

   var requestAvgTimeReport  = function(workflowId, start, end) {
      if (start.length == 0 || end.length == 0) {
         alert("Start and End dates are required");
         return;
      }
      $("#project-time-generating").show();
      $("#avg-time-raw table tbody tr.data").remove();
      var config = getBasicChartCfg("bar");
      config.options.scales =  {
         yAxes: [{
            ticks: {
               callback: function(value, index, values) {
                  return value + ' mins';
               }
            }
         }]
      };
      config.options.tooltips = {
         callbacks: {
            title: function(tooltipItem, data) {
               return data.datasets[0].label;
            },
            label: function(tooltipItem, data) {
               return Number(tooltipItem.yLabel) + " mins / page";
            }
         }
      };


      var qs = "workflow="+workflowId+"&start="+start+"&end="+end;
      url = "/api/reports?type=avg_time&"+qs;
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
      var config = getBasicChartCfg("bar");
      config.data.datasets[0].backgroundColor =  "#cc4444";

      var qs = "workflow="+workflowId+"&start="+start+"&end="+end;
      url = "/api/reports?type=problems&"+qs;
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

   var requestProductivityReport = function(workflowId, start, end) {
      if (start.length == 0 || end.length == 0) {
         alert("Start and End dates are required");
         return;
      }
      $("#project-productivity-generating").show();
      var config = getBasicChartCfg("bar");
      var qs = "workflow="+workflowId+"&start="+start+"&end="+end;
      $.getJSON("/api/reports?type=productivity&"+qs, function ( data, textStatus, jqXHR ){
         $("#project-productivity-generating").hide();
         if (textStatus == "success" ) {
            config.data.datasets[0].data = data.data;
            config.data.labels = data.labels;
            var canvas = document.getElementById("productivity-chart");
            var ctx = canvas.getContext("2d");
            if ( window.productivityChart ) {
               window.productivityChart.destroy();
            }
            window.productivityChart = new Chart(ctx, config);
            $("#total-productivity-projects").html("<b>Total Completed Projects:</b> "+data.total);
         }
      });
   };

   var requestDeliveriesReport = function(tgtYear) {
      $("#project-deliveries-generating").show();
      var config = getBasicChartCfg("line");
      config.options.legend.display = true;
      var qs = "year="+tgtYear;
      $.getJSON("/api/reports?type=deliveries&"+qs, function ( data, textStatus, jqXHR ){
         $("#project-deliveries-generating").hide();
         if (textStatus == "success" ) {
            config.data.datasets[0].data = data.ontime;
            config.data.datasets[0].fill = false;
            config.data.datasets[0].label = "On-Time";
            config.data.datasets[0].backgroundColor = "#44aacc";
            config.data.datasets[0].borderColor = "#44aacc";
            var errDataset = {data: data.late, backgroundColor: "#cc4444", fill: false, borderColor: "#cc4444", label: "Late"};
            config.data.datasets.push(errDataset);
            var totalDataset = {data: data.total, backgroundColor: "#44cc44", fill: false,
            borderColor: "#44cc44", label: "Total"};
            config.data.datasets.push(totalDataset);
            config.data.labels = data.labels;
            var canvas = document.getElementById("deliveries-chart");
            var ctx = canvas.getContext("2d");
            if ( window.deliveriesChart ) {
               window.deliveriesChart.destroy();
            }
            window.deliveriesChart = new Chart(ctx, config);
         }
      });
   };

   var requestRejectionsReport = function(workflowId, start, end, sort, dir) {
      if (start.length == 0 || end.length == 0) {
         alert("Start and End dates are required");
         return;
      }

      var template = "<tr class='data'><td>N</td><td class='left-bar'>SC</td><td>SR</td><td>SA</td>";
      template += "<td class='left-bar'>QC</td><td>QR</td><td>QA</td></tr>";
      var table = $("#rejection-stats tbody");
      $("#rejection-stats tbody tr.data").remove();
      $("#project-rejections-generating").show();
      var qs = "workflow="+workflowId+"&start="+start+"&end="+end;
      if ( sort ) qs = qs + "&sort=" + sort;
      if ( dir ) qs = qs + "&dir=" + dir;
      $.getJSON("/api/reports?type=rejections&"+qs, function ( data, textStatus, jqXHR ){
         $("#project-rejections-generating").hide();
         if (textStatus == "success" ) {
            for (var key in data) {
               var rowData = data[key];
               var row = template.replace("N", key);
               row = row.replace("SC", rowData.scans);
               row = row.replace("SR", rowData.scan_rejects);
               row = row.replace("SA", rowData.avg_scan_reject);
               row = row.replace("QC", rowData.qa);
               row = row.replace("QR", rowData.qa_rejects);
               row = row.replace("QA", rowData.avg_qa_reject);
               table.append(row);
            }
         }
      });
   };

   $(".refresh-report").on("click", function() {
      var id = $(this).attr("id");
      if (id == "deliveries") {
         requestDeliveriesReport( $(".deliveries.report-year").val() );
         return;
      }
      var sortBy = null;
      var sortDir = null;
      if (id == "rejections") {
         $("#rejection-stats .sort").each(function() {
            if ( $(this).hasClass("asc") ) {
               sortBy = $(this).data("tgt");
               sortDir = "asc";
               return false;
            } else if ( $(this).hasClass("desc") ) {
               sortBy = $(this).data("tgt");
               sortDir = "desc";
               return false;
            }
         });
      }

      var start = $(".report-start."+id).val();
      var end = $(".report-end."+id).val();
      var wfId = $(".workflow."+id).val();
      if (id == "problems") {
         requestProblemsReport(wfId, start, end);
      } else if (id == "productivity") {
         requestProductivityReport(wfId, start, end);
      } else if (id == "rejections") {
         requestRejectionsReport(wfId, start, end, sortBy, sortDir);
      } else {
         requestAvgTimeReport(wfId, start, end);
      }
   });

   if ( $("#avg-times").length > 0 ) {
      requestAvgTimeReport(1, $(".avg-time.report-start").val(), $(".avg-time.report-end").val());
      requestProductivityReport(1, $(".productivity.report-start").val(), $(".productivity.report-end").val());
      requestProblemsReport(1, $(".problems.report-start").val(), $(".problems.report-end").val());
      requestDeliveriesReport($(".deliveries.report-year").val());
      requestRejectionsReport(1,
         $(".rejections.report-start").val(),
         $(".rejections.report-end").val(),null,null);
   }

   $(".sort-clicker").on("click", function() {
      var sort = $(this).find(".sort");
      var newClass = "none";
      if (sort.hasClass("none")) {
         newClass="asc";
      } else if (sort.hasClass("asc")) {
         newClass="desc";
      } else if (sort.hasClass("desc")) {
         newClass="none";
      }
      $("#rejection-stats .sort").removeClass("none").removeClass("asc").removeClass("desc").addClass("none");
      $(sort).removeClass("none").addClass(newClass);
      $("#rejections").trigger("click");
   });
});
