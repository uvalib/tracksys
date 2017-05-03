$(function() {
   $("#processing-query-staff").chosen({
       no_results_text: "Sorry, no matches found",
       placeholder_text_single: "Select a user"
   });

   $('.query-datepicker').datepicker({
      changeMonth: true,
      changeYear: true,
      dateFormat: 'yy-mm-dd'
   });

   var issueStatsQuery = function(type, params, dimmer) {
      var url = "/admin/statistics/query?"+params.join("&");
      $.ajax({
         url: url,
         method: "GET",
         complete: function( jqXHR, textStatus ) {
            dimmer.hide();
            if ( jqXHR.status == 200) {
               $("#"+type+"-result").text( jqXHR.responseText )
            } else {
               alert("Query failed: "+jqXHR.responseText);
            }
         }
      });
   };

   var queryImageData = function(btn, type) {
      var query = $(btn).closest(".stats-query");
      var dimmer = query.find(".query-dimmer");
      dimmer.show();
      var params = ["type="+type];
      params.push("location="+$("#"+type+"-query-loc").val());
      var date = $("#"+type+"-query-start-date").val();
      if ( date.length > 0) {
         params.push("start_date="+date);
      }
      date = $("#"+type+"-query-end-date").val();
      if ( date.length > 0) {
         params.push("end_date="+date);
      }
      issueStatsQuery(type, params, dimmer);
   };

   $("#processed-query").on("click", function() {
      var query = $(this).closest(".stats-query");
      var dimmer = query.find(".query-dimmer");
      dimmer.show();
      var params = ["type=processed"];
      params.push("user="+$("#processed-query-user").val());
      var date = $("#processed-query-start-date").val();
      if ( date.length > 0) {
         params.push("start_date="+date);
      }
      date = $("#processed-query-end-date").val();
      if ( date.length > 0) {
         params.push("end_date="+date);
      }
      issueStatsQuery("processed", params, dimmer);
   });

   $("#image-query").on("click", function() {
      queryImageData(this, "image");
   });
   $("#size-query").on("click", function() {
      queryImageData(this, "size");
   });

   $("#unit-query").on("click", function() {
      var query = $(this).closest(".stats-query");
      var dimmer = query.find(".query-dimmer");
      dimmer.show();
      var params = ["type=unit"];
      params.push("status="+$("#unit-query-status").val());
      params.push("user="+$("#unit-query-user").val());
      var date = $("#unit-query-start-date").val();
      if ( date.length > 0) {
         params.push("start_date="+date);
      }
      date = $("#unit-query-end-date").val();
      if ( date.length > 0) {
         params.push("end_date="+date);
      }
      issueStatsQuery("unit", params, dimmer);
   });

   $("#metadata-query").on("click", function() {
      var query = $(this).closest(".stats-query");
      var dimmer = query.find(".query-dimmer");
      dimmer.show();
      var params = ["type=metadata"];
      params.push("location="+$("#metadata-query-loc").val());
      params.push("metadata="+$("#metadata-query-type").val());
      var date = $("#metadata-query-start-date").val();
      if ( date.length > 0) {
         params.push("start_date="+date);
      }
      date = $("#metadata-query-end-date").val();
      if ( date.length > 0) {
         params.push("end_date="+date);
      }
      issueStatsQuery("metadata", params, dimmer);
   });
});
