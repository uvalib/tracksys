$(function() {
   $('.query-datepicker').datepicker({
      changeMonth: true,
      changeYear: true,
      dateFormat: 'yy-mm-dd'
    });

   $("#image-query").on("click", function() {
      var query = $(this).closest(".stats-query");
      var dimmer = query.find(".query-dimmer");
      dimmer.show();
      var params = ["type=image"];
      params.push("location="+$("#image-query-loc").val());
      var date = $("#image-query-start-date").val();
      if ( date.length > 0) {
         params.push("start_date="+date);
      }
      date = $("#image-query-end-date").val();
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
               $("#image-result").text( jqXHR.responseText )
            } else {
               alert("Query failed: "+jqXHR.responseText);
            }
         }
      });
   });
});
