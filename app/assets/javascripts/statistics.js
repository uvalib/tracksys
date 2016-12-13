$(function() {
   $('.query-datepicker').datepicker({
      changeMonth: true,
      changeYear: true,
      dateFormat: 'yy-mm-dd'
   });

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

   $("#image-query").on("click", function() {
      queryImageData(this, "image");
   });
   $("#size-query").on("click", function() {
      queryImageData(this, "size");
   });
});
