$(function() {
   var requestAnnualReport = function() {
      var year = $("#report-year").val();
      var type = $("#report-type").val();
      $("div.report-data").html("<div class='generating-report'>Generating...</div>");
      $.getJSON("/admin/annual_reports/generate?type="+type+"&year="+year, function ( data, textStatus, jqXHR ){
         if (textStatus == "success" ) {
            $("div.report-data").html(data.html);
         }
      });
   };

   // detect annual reports page and request report
   if ( $("#generate-annual-report").length > 0 ) {
      requestAnnualReport();
   }
   $("#generate-annual-report").on("click", function() {
      requestAnnualReport();
   });
});
